local M = {}

function M.setup()
    vim.opt.background = "dark"
    vim.cmd("set whichwrap+=<,>,[,],h,l")
    vim.cmd([[set iskeyword+=-]])
    vim.cmd([[set laststatus=3]])

    vim.cmd([[set fillchars+=diff:\ ]])
    vim.cmd("colorscheme kanso-mist")

    vim.cmd("highlight WinSeparator guibg=none guifg=#4C566A")
end

return M
