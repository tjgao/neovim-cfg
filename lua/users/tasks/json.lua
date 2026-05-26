local json_doc = require("users.shared.json_doc")

local M = {}

function M.get_tasks_json_path(cwd)
    return (cwd or vim.fn.getcwd()) .. "/.vscode/tasks.json"
end

function M.read_tasks_json(path)
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

function M.write_tasks_json(path, tasks_doc)
    local directory = vim.fn.fnamemodify(path, ":h")
    if vim.fn.isdirectory(directory) == 0 then
        vim.fn.mkdir(directory, "p")
    end

    local serialized = json_doc.encode_json_pretty(tasks_doc) .. "\n"
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

function M.validate_task(task)
    if type(task) ~= "table" then
        return false, "Task must be a JSON object"
    end

    if type(task.label) ~= "string" or task.label == "" then
        return false, "Task requires a non-empty 'label' field"
    end

    return true
end

function M.label_conflict(tasks, label, current_index)
    if type(label) ~= "string" or label == "" then
        return false
    end

    for idx, task in ipairs(tasks) do
        if idx ~= current_index and type(task) == "table" and task.label == label then
            return true
        end
    end

    return false
end

function M.find_task_index_by_label(tasks, label)
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

function M.maybe_tasks_json_ref(label, cwd)
    local path = M.get_tasks_json_path(cwd)
    local tasks_doc = M.read_tasks_json(path)
    if not tasks_doc then
        return nil
    end
    local idx = M.find_task_index_by_label(tasks_doc.tasks, label)
    if not idx then
        return nil
    end
    return {
        kind = "tasks_json",
        label = label,
        cwd = cwd,
    }
end

function M.save_task_to_tasks_json(task, previous_index)
    local path = M.get_tasks_json_path()
    local tasks_doc, read_err = M.read_tasks_json(path)
    if not tasks_doc then
        vim.notify(read_err or "Failed to read tasks.json", vim.log.levels.ERROR)
        return false
    end

    local tasks = tasks_doc.tasks
    if M.label_conflict(tasks, task.label, previous_index) then
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

    if not M.write_tasks_json(path, tasks_doc) then
        return false
    end

    vim.notify(("Saved task '%s' to %s"):format(task.label, path), vim.log.levels.INFO)
    return true
end

function M.delete_task_from_tasks_json(source_index, fallback_label)
    local path = M.get_tasks_json_path()
    local tasks_doc, read_err = M.read_tasks_json(path)
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

    if not M.write_tasks_json(path, tasks_doc) then
        return false
    end

    vim.notify("Deleted task", vim.log.levels.INFO)
    return true
end

M.sanitize_for_json = json_doc.sanitize_for_json
M.encode_json_pretty = json_doc.encode_json_pretty

return M
