vim.opt["background"] = "dark"
vim.cmd("set whichwrap+=<,>,[,],h,l")
vim.cmd([[set iskeyword+=-]])
vim.cmd([[set laststatus=3]])

-- Do not want to see filler char in diff view
vim.cmd([[set fillchars+=diff:\ ]])

vim.cmd("colorscheme nord")

-- Steal from TJ's kickstart.nvim
vim.api.nvim_create_autocmd("TextYankPost", {
    desc = "Highlight when yanking (copying) text",
    group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
    callback = function()
        vim.highlight.on_yank()
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    pattern = "qf",
    group = vim.api.nvim_create_augroup("quickfix", { clear = true }),
    callback = function()
        vim.keymap.set("n", "<CR>", function()
            local cur = tostring(vim.fn.line("."))
            vim.cmd("cc" .. cur)
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
