local M = {}

function M.diffview_d(picker, item)
    vim.cmd(("DiffviewOpen %s^!"):format(item.commit))
    picker:close()
end

function M.diffview_D(picker, item)
    vim.cmd(("DiffviewOpen %s"):format(item.commit))
    picker:close()
end

function M.diffview_x(picker, item)
    picker:close()
    local fname = vim.api.nvim_buf_get_name(0)
    vim.cmd(("DiffviewOpen %s HEAD -- %s"):format(item.commit, fname))
end

function M.commit_to_cmd(picker, item)
    picker:close()
    local home = vim.api.nvim_replace_termcodes("<Home>", true, false, true)
    vim.api.nvim_feedkeys(":" .. item.commit .. home, "n", false)
end

function M.branch_to_cmd(picker, item)
    local branch = type(item) == "table" and item.branch or nil
    if type(branch) ~= "string" or branch == "" then
        vim.notify("No branch name found", vim.log.levels.WARN)
        return
    end

    picker:close()
    local home = vim.api.nvim_replace_termcodes("<Home>", true, false, true)
    vim.api.nvim_feedkeys(":" .. branch .. home, "n", false)
end

function M.commit_to_reg(picker, item)
    picker:close()
    vim.fn.setreg('"', item.commit)
    vim.fn.setreg("0", item.commit)
    vim.fn.setreg("+", item.commit)
end

function M.branch_to_reg(picker, item)
    local branch = type(item) == "table" and item.branch or nil
    if type(branch) ~= "string" or branch == "" then
        vim.notify("No branch name found", vim.log.levels.WARN)
        return
    end

    picker:close()
    vim.fn.setreg('"', branch)
    vim.fn.setreg("0", branch)
    vim.fn.setreg("+", branch)
end

return M
