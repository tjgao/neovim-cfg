require('toggleterm').setup{}

function _G.set_terminal_keymaps()
    local opts = { noremap = true }
    vim.api.nvim_buf_set_keymap(0, 't', '<c-\\>', [[<c-\><c-n>]], opts)
end

vim.cmd('autocmd! TermOpen term://* lua set_terminal_keymaps()')
-- vim.cmd('autocmd! BufEnter, BufWinEnter, WinEnter term://* lua startinsert')
-- autocmd BufWinEnter,WinEnter term://* startinsert


local Terminal  = require('toggleterm.terminal').Terminal

local opts = {noremap = true, silent = true}

local cfg = {
    {'<F2>', 'float'},
    {'<F3>', 'float'},
    {'<F4>', 'horizontal'},
}

local make_term = function(idx, o)
    return {
        count = idx,
        direction = o[2],
        float_opts = {
            border = 'curved',
        },
        close_on_exit = true, -- close the terminal window when the process exits
        start_in_insert = true,

        size = function(term)
            if term.direction == "horizontal" then
                return 20
            elseif term.direction == "vertical" then
                return vim.o.columns * 0.4
            end
        end,

        on_open = function(term)
            for i, v in pairs(cfg) do
                vim.api.nvim_buf_set_keymap(term.bufnr, 't', v[1], '<cmd>lua MyToggleTerm(' .. i .. ')<CR>', opts)
                vim.api.nvim_buf_set_keymap(term.bufnr, 'n', v[1], '<cmd>lua MyToggleTerm(' .. i .. ')<CR>', opts)
            end
            vim.cmd('startinsert')
        end,
    }
end

local term_table = {}

for i, o in pairs(cfg) do
    table.insert(term_table, Terminal:new(make_term(i, o)))
end

function MyToggleTerm(c)
    local opened = nil
    for _, o in pairs(term_table) do
        if o:is_open() then
            opened = o
            break
        end
    end

    local t = term_table[c]
    if t == opened then
        t:close()
    else
        if opened ~= nil then
            opened:close()
        end
        t:open()
    end
end

for i, v in pairs(cfg) do
    vim.api.nvim_buf_set_keymap(0, 'n', v[1], '<cmd>lua MyToggleTerm(' .. i .. ')<CR>', opts)
end
