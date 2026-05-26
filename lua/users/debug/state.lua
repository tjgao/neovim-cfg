local M = {}

local STATE = {
    initialized = false,
    js_enabled = false,
    active_prelaunch_tasks = {},
}

function M.is_initialized()
    return STATE.initialized
end

function M.set_initialized(value)
    STATE.initialized = value == true
end

function M.set_js_enabled(value)
    STATE.js_enabled = value == true
end

function M.get_prelaunch_task_names(config)
    if type(config) ~= "table" then
        return {}
    end

    local task_names = {}
    local prelaunch = config.preLaunchTask

    if type(prelaunch) == "string" and prelaunch ~= "" then
        task_names[#task_names + 1] = prelaunch
    elseif type(prelaunch) == "table" then
        for _, name in ipairs(prelaunch) do
            if type(name) == "string" and name ~= "" then
                task_names[#task_names + 1] = name
            end
        end
    end

    return task_names
end

function M.set_active_prelaunch_tasks_from_config(config)
    STATE.active_prelaunch_tasks = M.get_prelaunch_task_names(config)
end

function M.get_active_prelaunch_tasks()
    return STATE.active_prelaunch_tasks
end

function M.clear_active_prelaunch_tasks()
    STATE.active_prelaunch_tasks = {}
end

function M.stop_active_prelaunch_tasks()
    local task_names = STATE.active_prelaunch_tasks
    if type(task_names) ~= "table" or #task_names == 0 then
        return
    end

    local ok_overseer, overseer = pcall(require, "overseer")
    if not ok_overseer then
        M.clear_active_prelaunch_tasks()
        return
    end

    local stopped_names = {}

    for _, task_name in ipairs(task_names) do
        local tasks = overseer.list_tasks({
            status = "RUNNING",
            include_ephemeral = true,
            filter = function(task)
                return task.name == task_name
            end,
        })

        for _, task in ipairs(tasks) do
            task:stop()
        end

        if #tasks > 0 then
            stopped_names[#stopped_names + 1] = task_name
        end
    end

    if #stopped_names > 0 then
        vim.notify(("Stopped preLaunchTask(s): %s"):format(table.concat(stopped_names, ", ")), vim.log.levels.INFO)
    end

    M.clear_active_prelaunch_tasks()
end

return M
