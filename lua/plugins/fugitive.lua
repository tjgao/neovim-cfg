if not table.unpack then
    table.unpack = unpack
end
local group = vim.api.nvim_create_augroup("FugitiveDiffview", {})

local function get_sid(file)
    file = file or "autoload/fugitive.vim"
    local script_entry = vim.api.nvim_exec2("filter #vim-fugitive/" .. file .. "# scriptnames", { output = true })
    return tonumber(script_entry.output:gsub("^%s*", ""):match("^(%d+)"))
end

local function get_info_under_cursor()
    if vim.bo.ft ~= "fugitive" then
        return
    end
    local sid = get_sid()
    if sid then
        return vim.call(("<SNR>%d_StageInfo"):format(sid), vim.api.nvim_win_get_cursor(0)[1])
    end
end

local function diffview_cb_fugitive(ctx)
    -- Open diffview
    vim.keymap.set("n", "d", function()
        local info = get_info_under_cursor()
        if info then
            if #info.paths > 0 then
                vim.cmd(("DiffviewOpen --selected-file=%s"):format(vim.fn.fnameescape(info.paths[1])))
            elseif info.commit ~= "" then
                vim.cmd(("DiffviewOpen %s^!"):format(info.commit))
            else
                vim.cmd("DiffviewOpen")
            end
        end
    end, { buffer = ctx.buf })
end

vim.api.nvim_create_autocmd("FileType", {
    pattern = "fugitive",
    group = group,
    callback = diffview_cb_fugitive,
})

local function search_commit()
    local commit = nil
    local r, _ = table.unpack(vim.api.nvim_win_get_cursor(0))
    local get_commit_from_line = require("shared.utils").get_commit_from_line
    while r > 0 and commit == nil do
        commit = get_commit_from_line(r)
        r = r - 1
    end
    return commit
end

local function diffview_cb_git(ctx)
    vim.keymap.set("n", "d", function()
        local commit = search_commit()
        if commit ~= nil then
            vim.cmd(("DiffviewOpen %s^!"):format(commit))
        end
    end, { buffer = ctx.buf })
    vim.keymap.set("n", "D", function()
        local commit = search_commit()
        if commit ~= nil then
            vim.cmd(("DiffviewOpen %s"):format(commit))
        end
    end, { buffer = ctx.buf })
end

vim.api.nvim_create_autocmd("FileType", {
    pattern = "git",
    group = group,
    callback = diffview_cb_git,
})

vim.api.nvim_create_autocmd("FileType", {
    pattern = "fugitiveblame",
    group = group,
    callback = diffview_cb_git,
})

local function short_gitlog(args)
    vim.cmd('G log --pretty=format:"%h%x09%an%x09%ad%x09%s" --date=short ' .. args.args)
end

---@diagnostic disable-next-line: unused-local
local git_branch_complete = function(ArgLead, CmdLine, CursorPos)
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

vim.api.nvim_create_user_command("Gl", short_gitlog, {
    nargs = "*",
    complete = git_branch_complete,
    desc = "One line git log",
})

vim.api.nvim_create_user_command("Gb", function(args)
    vim.cmd("G branch " .. args.args)
end, {
    nargs = "*",
    desc = "Shortcut for git branch",
})

return {
    "tpope/vim-fugitive",
    dependencies = {
        "tpope/vim-rhubarb",
    },
}
