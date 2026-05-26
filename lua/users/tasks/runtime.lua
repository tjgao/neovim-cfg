local tasks_json = require("users.tasks.json")

local M = {}

local LAST_TASK_REF
local RUNNING_TASK_NOTIFS = {}
local RUNNING_TASK_TIMERS = {}
local SPINNER_FRAMES = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }

local function stop_running_spinner(task_id)
    local timer = RUNNING_TASK_TIMERS[task_id]
    RUNNING_TASK_TIMERS[task_id] = nil
    if timer then
        timer:stop()
        timer:close()
    end
end

local function attach_running_notification(task)
    local ok, notifier = pcall(require, "snacks.notifier")
    if not ok or type(notifier.notify) ~= "function" or type(notifier.hide) ~= "function" then
        return
    end

    local task_id = task.id
    if type(task_id) ~= "number" then
        return
    end

    local notif_id = ("overseer-task-running-%d"):format(task_id)
    stop_running_spinner(task_id)
    RUNNING_TASK_NOTIFS[task_id] = notif_id
    local frame_index = 1
    notifier.notify(("%s %s is running..."):format(SPINNER_FRAMES[frame_index], task.name), vim.log.levels.INFO, {
        id = notif_id,
        title = "Overseer",
        timeout = false,
    })

    local uv = vim.uv or vim.loop
    local timer = uv.new_timer()
    if timer then
        RUNNING_TASK_TIMERS[task_id] = timer
        timer:start(
            120,
            120,
            vim.schedule_wrap(function()
                if RUNNING_TASK_NOTIFS[task_id] ~= notif_id then
                    stop_running_spinner(task_id)
                    return
                end
                frame_index = (frame_index % #SPINNER_FRAMES) + 1
                notifier.notify(
                    ("%s %s is running..."):format(SPINNER_FRAMES[frame_index], task.name),
                    vim.log.levels.INFO,
                    {
                        id = notif_id,
                        title = "Overseer",
                        timeout = false,
                    }
                )
            end)
        )
    end

    local function close_running_notification()
        local id = RUNNING_TASK_NOTIFS[task_id]
        RUNNING_TASK_NOTIFS[task_id] = nil
        stop_running_spinner(task_id)
        if id then
            pcall(notifier.hide, id)
        end
    end

    task:subscribe("on_complete", function()
        close_running_notification()
        return true
    end)
    task:subscribe("on_dispose", function()
        close_running_notification()
        return true
    end)
    task:subscribe("on_result", function()
        if task:is_running() then
            close_running_notification()
            notifier.notify(("%s is running in background"):format(task.name), vim.log.levels.INFO, {
                title = "Overseer",
                timeout = 2500,
            })
            return true
        end
        return false
    end)
end

local function remember_last_template_task(task_name, search_params)
    if type(task_name) ~= "string" or task_name == "" then
        return
    end

    local cwd = vim.fn.getcwd()
    local tasks_ref = tasks_json.maybe_tasks_json_ref(task_name, cwd)
    if tasks_ref then
        LAST_TASK_REF = tasks_ref
        return
    end

    LAST_TASK_REF = {
        kind = "template",
        name = task_name,
        search_params = search_params,
    }
end

function M.run_task_picker_and_remember()
    local overseer = require("overseer")
    local search_params = {
        dir = vim.fn.getcwd(),
        filetype = vim.bo.filetype,
    }

    overseer.run_task({ search_params = search_params, autostart = false }, function(task)
        if task then
            remember_last_template_task(task.name, search_params)
            attach_running_notification(task)
            task:start()
        end
    end)
end

function M.run_task_by_label(label, source_index)
    local path = tasks_json.get_tasks_json_path()
    local tasks_doc, read_err = tasks_json.read_tasks_json(path)
    if not tasks_doc then
        vim.notify(read_err or "Failed to read tasks.json", vim.log.levels.ERROR)
        return
    end

    if tasks_json.label_conflict(tasks_doc.tasks, label, source_index) then
        vim.notify(("Duplicate task label '%s' is not allowed"):format(label), vim.log.levels.ERROR)
        return
    end

    local overseer = require("overseer")
    overseer.run_task({ name = label, autostart = false }, function(task, err)
        if not task then
            vim.notify(
                ("Could not run task '%s': %s"):format(label, tostring(err or "unknown error")),
                vim.log.levels.ERROR
            )
            return
        end
        LAST_TASK_REF = {
            kind = "tasks_json",
            label = label,
            cwd = vim.fn.getcwd(),
        }
        attach_running_notification(task)
        task:start()
    end)
end

function M.run_recent_task_action()
    local overseer = require("overseer")
    if type(LAST_TASK_REF) ~= "table" then
        M.run_task_picker_and_remember()
        return
    end

    if LAST_TASK_REF.kind == "tasks_json" then
        local cwd = type(LAST_TASK_REF.cwd) == "string" and LAST_TASK_REF.cwd or vim.fn.getcwd()
        local path = tasks_json.get_tasks_json_path(cwd)
        local tasks_doc = tasks_json.read_tasks_json(path)
        if not tasks_doc then
            M.run_task_picker_and_remember()
            return
        end

        local label = LAST_TASK_REF.label
        local idx = tasks_json.find_task_index_by_label(tasks_doc.tasks, label)
        if not idx then
            M.run_task_picker_and_remember()
            return
        end

        local current_cwd = vim.fn.getcwd()
        if current_cwd ~= cwd then
            vim.notify(("Last task belongs to %s; reopen there to rerun '%s'"):format(cwd, label), vim.log.levels.WARN)
            M.run_task_picker_and_remember()
            return
        end

        M.run_task_by_label(label, idx)
        return
    end

    if LAST_TASK_REF.kind == "template" then
        local name = LAST_TASK_REF.name
        local search_params = type(LAST_TASK_REF.search_params) == "table" and LAST_TASK_REF.search_params or nil

        overseer.run_task({
            name = name,
            search_params = search_params,
            autostart = false,
            first = true,
            disallow_prompt = true,
        }, function(task)
            if not task then
                M.run_task_picker_and_remember()
                return
            end
            remember_last_template_task(task.name, search_params)
            attach_running_notification(task)
            task:start()
        end)
        return
    end

    vim.notify("Invalid last task reference; falling back to task picker", vim.log.levels.WARN)
    M.run_task_picker_and_remember()
end

return M
