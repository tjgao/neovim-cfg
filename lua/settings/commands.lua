vim.opt["background"] = "dark"
vim.cmd("set whichwrap+=<,>,[,],h,l")
vim.cmd([[set iskeyword+=-]])
vim.cmd([[set laststatus=3]])

-- Do not want to see filler char in diff view
vim.cmd([[set fillchars+=diff:\ ]])

vim.cmd("colorscheme nightfox")

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
