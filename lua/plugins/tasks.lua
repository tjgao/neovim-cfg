local open_tasks_json_picker
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
end

local function sanitize_for_json(value)
    local value_type = type(value)
    if value == nil or value_type == "string" or value_type == "number" or value_type == "boolean" then
        return value
    end
    if value_type ~= "table" then
        return nil
    end

    if vim.islist(value) then
        local list = {}
        for _, item in ipairs(value) do
            local sanitized = sanitize_for_json(item)
            if sanitized ~= nil then
                list[#list + 1] = sanitized
            end
        end
        return list
    end

    local object = {}
    for key, item in pairs(value) do
        if type(key) == "string" then
            local sanitized = sanitize_for_json(item)
            if sanitized ~= nil then
                object[key] = sanitized
            end
        end
    end
    return object
end

local function encode_json_pretty(value, depth)
    depth = depth or 0
    local value_type = type(value)

    if value == nil then
        return "null"
    end
    if value_type == "string" then
        return vim.json.encode(value)
    end
    if value_type == "number" or value_type == "boolean" then
        return tostring(value)
    end
    if value_type ~= "table" then
        return "null"
    end

    local indent = string.rep("  ", depth)
    local child_indent = string.rep("  ", depth + 1)

    if vim.islist(value) then
        if #value == 0 then
            return "[]"
        end

        local parts = {}
        for _, item in ipairs(value) do
            parts[#parts + 1] = child_indent .. encode_json_pretty(item, depth + 1)
        end

        return "[\n" .. table.concat(parts, ",\n") .. "\n" .. indent .. "]"
    end

    local keys = vim.tbl_keys(value)
    table.sort(keys)
    if #keys == 0 then
        return "{}"
    end

    local parts = {}
    for _, key in ipairs(keys) do
        parts[#parts + 1] = child_indent .. vim.json.encode(key) .. ": " .. encode_json_pretty(value[key], depth + 1)
    end

    return "{\n" .. table.concat(parts, ",\n") .. "\n" .. indent .. "}"
end

local function get_tasks_json_path(cwd)
    return (cwd or vim.fn.getcwd()) .. "/.vscode/tasks.json"
end

local function read_tasks_json(path)
    if vim.fn.filereadable(path) == 0 then
        return {
            version = "2.0.0",
            tasks = {},
        }
    end

    local file = io.open(path, "r")
    if not file then
        return nil, ("Could not open %s for reading"):format(path)
    end
    local content = file:read("*a")
    file:close()

    local ok, parsed = pcall(vim.json.decode, content)
    if not ok then
        return nil, ("Invalid JSON in %s: %s"):format(path, parsed)
    end
    if type(parsed) ~= "table" then
        return nil, ("Invalid JSON in %s: root must be an object"):format(path)
    end

    if type(parsed.tasks) ~= "table" then
        parsed.tasks = {}
    end
    if type(parsed.version) ~= "string" or parsed.version == "" then
        parsed.version = "2.0.0"
    end

    return parsed
end

local function write_tasks_json(path, tasks_doc)
    local directory = vim.fn.fnamemodify(path, ":h")
    if vim.fn.isdirectory(directory) == 0 then
        vim.fn.mkdir(directory, "p")
    end

    local serialized = encode_json_pretty(tasks_doc) .. "\n"
    local file, open_err = io.open(path, "w")
    if not file then
        vim.notify(
            ("Could not open %s for writing: %s"):format(path, open_err or "unknown error"),
            vim.log.levels.ERROR
        )
        return false
    end

    file:write(serialized)
    file:close()
    return true
end

local function validate_task(task)
    if type(task) ~= "table" then
        return false, "Task must be a JSON object"
    end

    if type(task.label) ~= "string" or task.label == "" then
        return false, "Task requires a non-empty 'label' field"
    end

    return true
end

local function label_conflict(tasks, label, current_index)
    if type(label) ~= "string" or label == "" then
        return false
    end

    local count = 0
    for idx, task in ipairs(tasks) do
        if idx ~= current_index and type(task) == "table" and task.label == label then
            count = count + 1
            if count > 0 then
                return true
            end
        end
    end

    return false
end

local function find_task_index_by_label(tasks, label)
    local found_index = nil
    for idx, task in ipairs(tasks or {}) do
        if type(task) == "table" and task.label == label then
            if found_index ~= nil then
                return nil
            end
            found_index = idx
        end
    end
    return found_index
end

local function maybe_tasks_json_ref(label, cwd)
    local path = get_tasks_json_path(cwd)
    local tasks_doc = read_tasks_json(path)
    if not tasks_doc then
        return nil
    end
    local idx = find_task_index_by_label(tasks_doc.tasks, label)
    if not idx then
        return nil
    end
    return {
        kind = "tasks_json",
        label = label,
        cwd = cwd,
    }
end

local function remember_last_template_task(task_name, search_params)
    if type(task_name) ~= "string" or task_name == "" then
        return
    end

    local cwd = vim.fn.getcwd()
    local tasks_ref = maybe_tasks_json_ref(task_name, cwd)
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

local function run_task_picker_and_remember()
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

local function save_task_to_tasks_json(task, previous_index)
    local path = get_tasks_json_path()
    local tasks_doc, read_err = read_tasks_json(path)
    if not tasks_doc then
        vim.notify(read_err or "Failed to read tasks.json", vim.log.levels.ERROR)
        return false
    end

    local tasks = tasks_doc.tasks
    if label_conflict(tasks, task.label, previous_index) then
        vim.notify(("Duplicate task label '%s' is not allowed"):format(task.label), vim.log.levels.ERROR)
        return false
    end

    local replaced = false
    if type(previous_index) == "number" and previous_index >= 1 and previous_index <= #tasks then
        tasks[previous_index] = vim.deepcopy(task)
        replaced = true
    end
    if not replaced then
        tasks[#tasks + 1] = vim.deepcopy(task)
    end

    if not write_tasks_json(path, tasks_doc) then
        return false
    end

    vim.notify(("Saved task '%s' to %s"):format(task.label, path), vim.log.levels.INFO)
    return true
end

local function delete_task_from_tasks_json(source_index, fallback_label)
    local path = get_tasks_json_path()
    local tasks_doc, read_err = read_tasks_json(path)
    if not tasks_doc then
        vim.notify(read_err or "Failed to read tasks.json", vim.log.levels.ERROR)
        return false
    end

    local tasks = tasks_doc.tasks
    local removed = false
    if type(source_index) == "number" and source_index >= 1 and source_index <= #tasks then
        table.remove(tasks, source_index)
        removed = true
    elseif type(fallback_label) == "string" and fallback_label ~= "" then
        for idx, task in ipairs(tasks) do
            if type(task) == "table" and task.label == fallback_label then
                table.remove(tasks, idx)
                removed = true
                break
            end
        end
    end

    if not removed then
        vim.notify("Could not find task to delete", vim.log.levels.WARN)
        return false
    end

    if not write_tasks_json(path, tasks_doc) then
        return false
    end

    vim.notify("Deleted task", vim.log.levels.INFO)
    return true
end

local function run_task_by_label(label, source_index)
    local path = get_tasks_json_path()
    local tasks_doc, read_err = read_tasks_json(path)
    if not tasks_doc then
        vim.notify(read_err or "Failed to read tasks.json", vim.log.levels.ERROR)
        return
    end

    if label_conflict(tasks_doc.tasks, label, source_index) then
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

local function run_recent_task_action()
    local overseer = require("overseer")
    if type(LAST_TASK_REF) ~= "table" then
        run_task_picker_and_remember()
        return
    end

    if LAST_TASK_REF.kind == "tasks_json" then
        local cwd = type(LAST_TASK_REF.cwd) == "string" and LAST_TASK_REF.cwd or vim.fn.getcwd()
        local path = get_tasks_json_path(cwd)
        local tasks_doc = read_tasks_json(path)
        if not tasks_doc then
            run_task_picker_and_remember()
            return
        end

        local label = LAST_TASK_REF.label
        local idx = find_task_index_by_label(tasks_doc.tasks, label)
        if not idx then
            run_task_picker_and_remember()
            return
        end

        local current_cwd = vim.fn.getcwd()
        if current_cwd ~= cwd then
            vim.notify(("Last task belongs to %s; reopen there to rerun '%s'"):format(cwd, label), vim.log.levels.WARN)
            run_task_picker_and_remember()
            return
        end

        run_task_by_label(label, idx)
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
                run_task_picker_and_remember()
                return
            end
            remember_last_template_task(task.name, search_params)
            attach_running_notification(task)
            task:start()
        end)
        return
    end

    vim.notify("Invalid last task reference; falling back to task picker", vim.log.levels.WARN)
    run_task_picker_and_remember()
end

local function task_templates()
    return {
        {
            label = "Shell (generic)",
            task = {
                label = "new-shell-task",
                type = "shell",
                command = "echo",
                args = { "hello" },
                options = {
                    cwd = "${workspaceFolder}",
                },
                problemMatcher = {},
            },
        },
        {
            label = "C++ build (g++)",
            task = {
                label = "cpp-build",
                type = "shell",
                command = "g++",
                args = { "-g", "${file}", "-o", "${workspaceFolder}/build/${fileBasenameNoExtension}" },
                options = {
                    cwd = "${workspaceFolder}",
                },
                group = "build",
                problemMatcher = { "$gcc" },
                presentation = {
                    revealProblems = "onProblem",
                },
            },
        },
        {
            label = "Rust cargo build",
            task = {
                label = "cargo-build",
                type = "shell",
                command = "cargo",
                args = { "build" },
                options = {
                    cwd = "${workspaceFolder}",
                },
                group = "build",
                problemMatcher = { "$rustc" },
            },
        },
        {
            label = "Rust cargo test",
            task = {
                label = "cargo-test",
                type = "shell",
                command = "cargo",
                args = { "test" },
                options = {
                    cwd = "${workspaceFolder}",
                },
                group = "test",
                problemMatcher = { "$rustc" },
            },
        },
        {
            label = "Frontend dev (npm)",
            task = {
                label = "frontend-dev",
                type = "shell",
                command = "npm",
                args = { "run", "dev" },
                options = {
                    cwd = "${workspaceFolder}",
                },
                isBackground = true,
                problemMatcher = {},
            },
        },
        {
            label = "Frontend build (npm)",
            task = {
                label = "frontend-build",
                type = "shell",
                command = "npm",
                args = { "run", "build" },
                options = {
                    cwd = "${workspaceFolder}",
                },
                group = "build",
                problemMatcher = {},
            },
        },
        {
            label = "Empty task",
            task = {
                label = "new-task",
                type = "shell",
                command = "",
                args = {},
                options = {
                    cwd = "${workspaceFolder}",
                },
                problemMatcher = {},
                dependsOn = {},
            },
        },
    }
end

local function open_task_editor(selected_task, picker, source_index, picker_item, refresh_picker)
    local sanitized = sanitize_for_json(vim.deepcopy(selected_task))
    local valid, err = validate_task(sanitized)
    if not valid then
        vim.notify(err or "Invalid task", vim.log.levels.ERROR)
        return
    end

    local sanitized_table = type(sanitized) == "table" and sanitized or {}
    local lines = vim.split(encode_json_pretty(sanitized_table), "\n", { plain = true })
    local tasks_json_path = get_tasks_json_path()
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(buf, tasks_json_path)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

    local width = math.min(math.floor(vim.o.columns * 0.75), 110)
    local height = math.min(math.floor(vim.o.lines * 0.75), 32)
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)
    local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        style = "minimal",
        border = "single",
        width = width,
        height = height,
        row = row,
        col = col,
    })

    vim.bo[buf].buftype = "acwrite"
    vim.bo[buf].swapfile = false
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].modifiable = true
    vim.bo[buf].filetype = "json"
    vim.bo[buf].undofile = false
    vim.wo[win].winblend = 0

    local picker_hidden = false
    if picker and picker.layout and type(picker.layout.hide) == "function" then
        local ok = pcall(function()
            picker.layout:hide()
        end)
        picker_hidden = ok
    end

    local function close_editor(restore_picker)
        if restore_picker == nil then
            restore_picker = true
        end

        if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_close(win, true)
        end

        if
            restore_picker
            and picker_hidden
            and picker
            and not picker.closed
            and picker.layout
            and type(picker.layout.unhide) == "function"
        then
            pcall(function()
                picker.layout:unhide()
            end)
            vim.schedule(function()
                if picker and not picker.closed and type(picker.focus) == "function" then
                    pcall(function()
                        picker:focus("list")
                    end)
                end
            end)
        end
    end

    local function close_picker()
        if picker and type(picker.close) == "function" then
            picker:close()
        end
    end

    local function parse_editor_task()
        local content = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
        local ok, parsed = pcall(vim.json.decode, content)
        if not ok then
            vim.notify("Invalid JSON: " .. tostring(parsed), vim.log.levels.ERROR)
            return nil
        end

        local parsed_valid, parsed_err = validate_task(parsed)
        if not parsed_valid then
            vim.notify(parsed_err or "Invalid task", vim.log.levels.ERROR)
            return nil
        end

        return parsed
    end

    local function save_from_editor()
        local parsed = parse_editor_task()
        if not parsed then
            return false
        end

        if save_task_to_tasks_json(parsed, source_index) then
            vim.bo[buf].modified = false

            if picker_item then
                local label = type(parsed.label) == "string" and parsed.label or "(unlabeled)"
                local task_type = type(parsed.type) == "string" and parsed.type or "?"
                local command = type(parsed.command) == "string" and parsed.command or "(no command)"
                picker_item.item = vim.deepcopy(parsed)
                picker_item.text = ("%s [%s] %s"):format(label, task_type, command)

                local tasks_doc = read_tasks_json(get_tasks_json_path())
                if tasks_doc then
                    picker_item.source_index = find_task_index_by_label(tasks_doc.tasks, label)
                end
            end

            if refresh_picker then
                refresh_picker(parsed)
            end

            return true, parsed
        end

        return false
    end

    local function run_from_editor()
        local did_save, parsed = save_from_editor()
        if not did_save or not parsed then
            return
        end

        close_editor(false)
        close_picker()
        vim.schedule(function()
            run_task_by_label(parsed.label, source_index)
        end)
    end

    local opts = { buffer = buf, silent = true, nowait = true }
    vim.api.nvim_create_autocmd("BufWriteCmd", {
        buffer = buf,
        callback = save_from_editor,
    })
    vim.keymap.set("n", "q", close_editor, vim.tbl_extend("force", opts, { desc = "Close editor" }))
    vim.keymap.set("n", "R", run_from_editor, vim.tbl_extend("force", opts, { desc = "Save and run task" }))
    vim.keymap.set("n", "<S-r>", run_from_editor, vim.tbl_extend("force", opts, { desc = "Save and run task" }))
end

local function choose_new_task_template(picker, on_saved)
    local templates = task_templates()
    local menu = { "Select task template:" }
    for i, template in ipairs(templates) do
        menu[#menu + 1] = ("%d. %s"):format(i, template.label)
    end

    local selected = vim.fn.inputlist(menu)
    local choice = templates[selected]
    if not choice then
        if picker and not picker.closed and type(picker.focus) == "function" then
            picker:focus("list")
        end
        return
    end

    open_task_editor(choice.task, picker, nil, nil, on_saved)
end

local function show_tasks_json_picker(tasks)
    local items = {}
    for index, task in ipairs(tasks) do
        local label = type(task.label) == "string" and task.label or "(unlabeled)"
        local task_type = type(task.type) == "string" and task.type or "?"
        local command = type(task.command) == "string" and task.command or "(no command)"

        items[#items + 1] = {
            text = ("%s [%s] %s"):format(label, task_type, command),
            item = task,
            source_index = index,
        }
    end

    table.sort(items, function(a, b)
        return a.text < b.text
    end)

    if #items == 0 then
        items[1] = {
            text = "No tasks found. Press A to add one",
            item = nil,
            source_index = nil,
            is_placeholder = true,
        }
    end

    local function refresh_picker(picker)
        table.sort(items, function(a, b)
            return a.text < b.text
        end)
        if picker and not picker.closed and type(picker.find) == "function" then
            picker:find()
        end
    end

    local Snacks = require("snacks")
    Snacks.picker.pick({
        source = "select",
        title = "tasks.json (Enter run, E edit, A add, D delete)",
        focus = "list",
        auto_close = false,
        format = "text",
        preview = "none",
        finder = function()
            return items
        end,
        confirm = function(picker, item)
            if not item then
                return
            end
            if item.is_placeholder then
                choose_new_task_template(picker)
                return
            end
            if not item.item then
                return
            end

            local label = type(item.item.label) == "string" and item.item.label or ""
            if label == "" then
                vim.notify("Task requires a non-empty 'label' field", vim.log.levels.ERROR)
                return
            end

            picker:close()
            run_task_by_label(label, item.source_index)
        end,
        actions = {
            edit_task = function(picker, item)
                if not item or not item.item then
                    return
                end
                open_task_editor(item.item, picker, item.source_index, item, function()
                    refresh_picker(picker)
                end)
            end,
            add_task = function(picker)
                local added_item = nil
                choose_new_task_template(picker, function(parsed)
                    local label = type(parsed.label) == "string" and parsed.label or "(unlabeled)"
                    local task_type = type(parsed.type) == "string" and parsed.type or "?"
                    local command = type(parsed.command) == "string" and parsed.command or "(no command)"

                    if not added_item then
                        for i = #items, 1, -1 do
                            if items[i].is_placeholder then
                                table.remove(items, i)
                            end
                        end

                        added_item = {
                            text = ("%s [%s] %s"):format(label, task_type, command),
                            item = vim.deepcopy(parsed),
                            source_index = nil,
                        }
                        items[#items + 1] = added_item
                    else
                        added_item.item = vim.deepcopy(parsed)
                        added_item.text = ("%s [%s] %s"):format(label, task_type, command)
                    end

                    local tasks_doc = read_tasks_json(get_tasks_json_path())
                    if tasks_doc then
                        added_item.source_index = find_task_index_by_label(tasks_doc.tasks, label)
                    end

                    refresh_picker(picker)
                end)
            end,
            delete_task = function(picker, item)
                if not item or not item.item then
                    return
                end

                local task_label = type(item.item.label) == "string" and item.item.label or "(unlabeled)"
                local choice = vim.fn.confirm(("Delete task '%s'?"):format(task_label), "&No\n&Yes", 1)
                if choice ~= 2 then
                    return
                end

                if delete_task_from_tasks_json(item.source_index, task_label) then
                    picker:close()
                    open_tasks_json_picker()
                end
            end,
        },
        win = {
            list = {
                keys = {
                    ["E"] = "edit_task",
                    ["A"] = "add_task",
                    ["D"] = "delete_task",
                },
            },
        },
    })
end

open_tasks_json_picker = function()
    local path = get_tasks_json_path()
    local tasks_doc, read_err = read_tasks_json(path)
    if not tasks_doc then
        vim.notify(read_err or "Failed to read tasks.json", vim.log.levels.ERROR)
        return
    end

    show_tasks_json_picker(tasks_doc.tasks or {})
end

return {
    "stevearc/overseer.nvim",
    cmd = {
        "OverseerRun",
        "OverseerToggle",
        "OverseerTaskAction",
        "OverseerInfo",
    },
    keys = {
        { "<leader>tr", run_task_picker_and_remember,  desc = "Overseer run task" },
        { "<leader>tt", "<cmd>OverseerToggle<cr>",     desc = "Overseer toggle list" },
        { "<leader>ta", "<cmd>OverseerTaskAction<cr>", desc = "Overseer task action" },
        { "<leader>tq", run_recent_task_action,        desc = "Run last task or pick" },
        {
            "<leader>tm",
            function()
                open_tasks_json_picker()
            end,
            desc = "Manage tasks.json",
        },
        { "<S-F5>", run_recent_task_action, desc = "Run last task or pick" },
        { "<F17>",  run_recent_task_action, desc = "Run last task or pick" },
    },
    opts = {
        dap = true,
    },
    config = function(_, opts)
        require("overseer").setup(opts)
    end,
}
