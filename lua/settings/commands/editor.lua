local M = {}

function M.setup()
    vim.opt.background = "dark"
    vim.cmd("set whichwrap+=<,>,[,],h,l")
    vim.cmd([[set iskeyword+=-]])
    vim.cmd([[set laststatus=3]])

    vim.cmd([[set fillchars+=diff:\ ]])
    vim.cmd("colorscheme " .. (vim.fn.has("wsl") == 1 and "kanso-mist" or "kanso-ink"))

    vim.cmd("highlight WinSeparator guibg=none guifg=#4C566A")
end

return M
