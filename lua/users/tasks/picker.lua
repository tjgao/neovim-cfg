local task_editor = require("users.tasks.editor")
local tasks_json = require("users.tasks.json")
local task_runtime = require("users.tasks.runtime")

local M = {}

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

    task_editor.open_task_editor(choice.task, picker, nil, nil, on_saved, {
        run_task_by_label = task_runtime.run_task_by_label,
    })
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
            task_runtime.run_task_by_label(label, item.source_index)
        end,
        actions = {
            edit_task = function(picker, item)
                if not item or not item.item then
                    return
                end
                task_editor.open_task_editor(item.item, picker, item.source_index, item, function()
                    refresh_picker(picker)
                end, {
                    run_task_by_label = task_runtime.run_task_by_label,
                })
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

                    local tasks_doc = tasks_json.read_tasks_json(tasks_json.get_tasks_json_path())
                    if tasks_doc then
                        added_item.source_index = tasks_json.find_task_index_by_label(tasks_doc.tasks, label)
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

                if tasks_json.delete_task_from_tasks_json(item.source_index, task_label) then
                    picker:close()
                    M.open_tasks_json_picker()
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

function M.open_tasks_json_picker()
    local path = tasks_json.get_tasks_json_path()
    local tasks_doc, read_err = tasks_json.read_tasks_json(path)
    if not tasks_doc then
        vim.notify(read_err or "Failed to read tasks.json", vim.log.levels.ERROR)
        return
    end

    show_tasks_json_picker(tasks_doc.tasks or {})
end

return M
