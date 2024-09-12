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

return M
