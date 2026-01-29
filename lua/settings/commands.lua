vim.opt["background"] = "dark"
vim.cmd("set whichwrap+=<,>,[,],h,l")
vim.cmd([[set iskeyword+=-]])
vim.cmd([[set laststatus=3]])

-- Do not want to see filler char in diff view
vim.cmd([[set fillchars+=diff:\ ]])

vim.cmd("colorscheme kanso-ink")

-- Steal from TJ's kickstart.nvim
vim.api.nvim_create_autocmd("TextYankPost", {
    desc = "Highlight when yanking (copying) text",
    group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
    callback = function()
        vim.highlight.on_yank()
    end,
})

vim.api.nvim_create_autocmd("BufReadPost", {
    desc = "Go to the last location when openning a buffer",
    group = vim.api.nvim_create_augroup("last_location", { clear = true }),
    callback = function(args)
        local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
        local line_count = vim.api.nvim_buf_line_count(args.buf)
        if mark[1] > 0 and mark[1] <= line_count then
            vim.cmd('normal! g`"zz')
        end
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    pattern = "qf",
    group = vim.api.nvim_create_augroup("quickfix", { clear = true }),
    callback = function()
        local winid = vim.api.nvim_get_current_win()
        local win_info = vim.fn.getwininfo(winid)[1]
        local cmd
        if win_info["loclist"] == 1 then
            cmd = "ll"
        elseif win_info["quickfix"] == 1 then
            cmd = "cc"
        else
            return
        end
        vim.keymap.set("n", "<CR>", function()
            local cur = tostring(vim.fn.line("."))
            vim.cmd(cmd .. cur)
        end)
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

vim.api.nvim_create_user_command("Df", function(opts)
    local args = table.concat(opts.fargs, " ")
    vim.cmd(("DiffviewOpen %s"):format(args))
end, { nargs = "*" })

vim.api.nvim_create_user_command("T", function(opts)
    local args = table.concat(opts.fargs, " ")
    vim.cmd(("tab split | %s"):format(args))
end, { nargs = "*", desc = "Create a tab and execute command" })

vim.api.nvim_create_user_command("Tvd", function(opts)
    if #opts.fargs == 0 then
        return
    end
    vim.print("tab split | vertical diffsplit " .. opts.fargs[1])
    vim.cmd("tab split | vertical diffsplit " .. opts.fargs[1])
end, { nargs = 1, desc = "Create a tab and diff the file with current buffer" })
