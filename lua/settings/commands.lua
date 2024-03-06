
vim.opt['background'] = 'dark'
vim.cmd "set whichwrap+=<,>,[,],h,l"
vim.cmd [[set iskeyword+=-]]
vim.cmd [[set laststatus=3]]

-- Do not want to see filler char in diff view
vim.cmd [[set fillchars+=diff:\ ]]

vim.cmd('colorscheme nightfox')

-- Steal from TJ's kickstart.nvim
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- We have new global status line so we want to disable bg color for window separator
-- also, pick a nicer fg color
vim.cmd "highlight WinSeparator guibg=none guifg=#4C566A"


-- Close all buffers except current
local function close_allbuf_except_current()
    local cur = vim.api.nvim_win_get_buf(0)
    for _, o in pairs(vim.api.nvim_list_bufs()) do
        if o ~= cur then
            vim.api.nvim_buf_delete(o, {})
        end
    end
end

vim.api.nvim_create_user_command('Bd', close_allbuf_except_current, {})
