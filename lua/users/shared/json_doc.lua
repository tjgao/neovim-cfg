local M = {}

function M.sanitize_for_json(value)
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
            local sanitized = M.sanitize_for_json(item)
            if sanitized ~= nil then
                list[#list + 1] = sanitized
            end
        end
        return list
    end

    local object = {}
    for key, item in pairs(value) do
        if type(key) == "string" then
            local sanitized = M.sanitize_for_json(item)
            if sanitized ~= nil then
                object[key] = sanitized
            end
        end
    end
    return object
end

function M.encode_json_pretty(value, depth)
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
            parts[#parts + 1] = child_indent .. M.encode_json_pretty(item, depth + 1)
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
        parts[#parts + 1] = child_indent .. vim.json.encode(key) .. ": " .. M.encode_json_pretty(value[key], depth + 1)
    end

    return "{\n" .. table.concat(parts, ",\n") .. "\n" .. indent .. "}"
end

return M
