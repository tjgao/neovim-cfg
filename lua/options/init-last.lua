vim.cmd "set whichwrap+=<,>,[,],h,l"
vim.cmd [[set iskeyword+=-]]
vim.cmd [[set laststatus=3]]

-- now we have new global status line so we want to disable bg color for window separator
-- also, pick a nicer fg color
vim.cmd "highlight WinSeparator guibg=none guifg=#4C566A"

-- Do not want to see filler char in diff view
vim.cmd [[set fillchars+=diff:\ ]]
