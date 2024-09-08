vim.opt["background"] = "dark"
vim.cmd("set whichwrap+=<,>,[,],h,l")
vim.cmd([[set iskeyword+=-]])
vim.cmd([[set laststatus=3]])

-- Do not want to see filler char in diff view
vim.cmd([[set fillchars+=diff:\ ]])

vim.cmd("colorscheme iceberg")

-- Steal from TJ's kickstart.nvim
vim.api.nvim_create_autocmd("TextYankPost", {
    desc = "Highlight when yanking (copying) text",
    group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
    callback = function()
        vim.highlight.on_yank()
    end,
})

-- We have new global status line so we want to disable bg color for window separator
-- also, pick a nicer fg color
vim.cmd("highlight WinSeparator guibg=none guifg=#4C566A")

local function toggle_spell()
    local ok, notify = pcall(require, "notify")
    if vim.o.spell then
        vim.o.spell = false
        if ok then
            notify.notify("Spell turned off")
        end
    else
        vim.o.spell = true
        if ok then
            notify.notify("Spell turned on")
        end
    end
end

vim.api.nvim_create_user_command("Spell", toggle_spell, { desc = "Toggle spell" })

local function short_gitlog(args)
    vim.cmd('G log --pretty=format:"%h%x09%an%x09%ad%x09%s" --date=short ' .. args.args)
end

---@diagnostic disable-next-line: unused-local
local function short_gitlog_complete(ArgLead, CmdLine, CursorPos)
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
    complete = short_gitlog_complete,
    desc = "One line git log",
})
