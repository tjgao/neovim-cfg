local M = {}

function M.mtime_token(path)
    local uv = vim.uv or vim.loop
    local stat = uv.fs_stat(path)
    if not stat or not stat.mtime then
        return nil
    end
    local sec = stat.mtime.sec or 0
    local nsec = stat.mtime.nsec or 0
    local size = stat.size or 0
    return string.format("%s:%d:%d:%d", path, sec, nsec, size)
end

function M.get_path(cwd)
    return (cwd or vim.fn.getcwd()) .. "/.vscode/launch.json"
end

function M.has(path)
    return vim.fn.filereadable(path or M.get_path()) == 1
end

function M.sanitize(value)
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
            local sanitized = M.sanitize(item)
            if sanitized ~= nil then
                list[#list + 1] = sanitized
            end
        end
        return list
    end

    local object = {}
    for key, item in pairs(value) do
        if type(key) == "string" then
            local sanitized = M.sanitize(item)
            if sanitized ~= nil then
                object[key] = sanitized
            end
        end
    end
    return object
end

function M.encode_pretty(value, depth)
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
            parts[#parts + 1] = child_indent .. M.encode_pretty(item, depth + 1)
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
        parts[#parts + 1] = child_indent .. vim.json.encode(key) .. ": " .. M.encode_pretty(value[key], depth + 1)
    end

    return "{\n" .. table.concat(parts, ",\n") .. "\n" .. indent .. "}"
end

function M.validate_config(config)
    if type(config) ~= "table" then
        return false, "Configuration must be a JSON object"
    end

    local required = { "name", "type", "request" }
    for _, field in ipairs(required) do
        if type(config[field]) ~= "string" or config[field] == "" then
            return false, ("Configuration requires a non-empty '%s' field"):format(field)
        end
    end

    return true
end

function M.read(path)
    if vim.fn.filereadable(path) == 0 then
        return {
            version = "0.2.0",
            configurations = {},
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

    if type(parsed.configurations) ~= "table" then
        parsed.configurations = {}
    end
    if type(parsed.version) ~= "string" or parsed.version == "" then
        parsed.version = "0.2.0"
    end

    return parsed
end

function M.write(path, launch, opts)
    opts = opts or {}
    local directory = vim.fn.fnamemodify(path, ":h")
    if vim.fn.isdirectory(directory) == 0 then
        vim.fn.mkdir(directory, "p")
    end

    local serialized = M.encode_pretty(launch) .. "\n"
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
    if type(opts.on_write) == "function" then
        opts.on_write(path, launch)
    end
    return true
end

function M.save_config(config, previous_index, path, opts)
    opts = opts or {}
    local launch, read_err = M.read(path)
    if not launch then
        vim.notify(read_err or "Failed to read launch.json", vim.log.levels.ERROR)
        return false
    end

    local configurations = launch.configurations
    local replaced = false
    if type(previous_index) == "number" and previous_index >= 1 and previous_index <= #configurations then
        configurations[previous_index] = vim.deepcopy(config)
        replaced = true
    end

    if not replaced then
        configurations[#configurations + 1] = vim.deepcopy(config)
    end

    if not M.write(path, launch, opts) then
        return false
    end

    vim.notify(("Saved debug configuration '%s' to %s"):format(config.name, path), vim.log.levels.INFO)
    return true
end

function M.delete_config(source_index, fallback_name, path, opts)
    opts = opts or {}
    local launch, read_err = M.read(path)
    if not launch then
        vim.notify(read_err or "Failed to read launch.json", vim.log.levels.ERROR)
        return false
    end

    local configurations = launch.configurations
    local removed = false
    if type(source_index) == "number" and source_index >= 1 and source_index <= #configurations then
        table.remove(configurations, source_index)
        removed = true
    elseif type(fallback_name) == "string" and fallback_name ~= "" then
        for i, item in ipairs(configurations) do
            if type(item) == "table" and item.name == fallback_name then
                table.remove(configurations, i)
                removed = true
                break
            end
        end
    end

    if not removed then
        vim.notify("Could not find config to delete", vim.log.levels.WARN)
        return false
    end

    if not M.write(path, launch, opts) then
        return false
    end

    vim.notify("Deleted debug configuration", vim.log.levels.INFO)
    return true
end

function M.load_dap_configs(path)
    local ok, configs_or_err = pcall(function()
        return require("dap.ext.vscode").getconfigs(path)
    end)

    if not ok then
        vim.notify("Failed loading launch.json configs: " .. tostring(configs_or_err), vim.log.levels.WARN)
        return {}
    end

    return configs_or_err or {}
end

return M
