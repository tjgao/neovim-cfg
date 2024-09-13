-- util functions shared across plugins
--
local M = {}

M.get_visual_selection = function()
    local s_start = vim.fn.getpos("'<")
    local s_end = vim.fn.getpos("'>")
    local n_lines = math.abs(s_end[2] - s_start[2]) + 1
    local lines = vim.api.nvim_buf_get_lines(0, s_start[2] - 1, s_end[2], false)
    lines[n_lines] = string.sub(lines[n_lines], 1, s_end[3])
    lines[1] = string.sub(lines[1], s_start[3], -1)
    return table.concat(lines, "\n")
end

M.valid_commit_hash = function(hash)
    local obj = vim.system({ "git", "show", hash }, { text = true }):wait()
    if not obj or obj.code ~= 0 then
        return false
    end
    return true
end

---@diagnostic disable-next-line: unused-local
M.git_branch_complete = function(ArgLead, CmdLine, CursorPos)
    local lst = {}
    local cmd = vim.split(vim.trim(CmdLine), " ")
    if #cmd > 0 then
        local obj = vim.system({ "git", "branch" }, { text = true }):wait()
        if obj and obj.code == 0 then
            for _, val in ipairs(vim.split(obj.stdout, "\n")) do
                val = string.gsub(vim.trim(val), "^*%s*", "")
                if val ~= "" then
                    table.insert(lst, val)
                end
            end
        end
    end
    return lst
end

local function search_commit_hash(line)
    for i in string.gmatch(line, "%S+") do
        local hash = string.match(i, "^%x+$")
        if hash ~= nil and #hash >= 7 and M.valid_commit_hash(hash) then
            return hash
        end
    end
end

M.get_commit_from_line = function(row)
    local line = vim.trim(vim.api.nvim_buf_get_lines(0, row - 1, row, true)[1])
    return search_commit_hash(line)
end

return M
