require('toggleterm').setup{}

function _G.set_terminal_keymaps()
    local opts = { noremap = true }
    vim.api.nvim_buf_set_keymap(0, 't', '<c-\\>', [[<c-\><c-n>]], opts)
end

vim.cmd('autocmd! TermOpen term://* lua set_terminal_keymaps()')


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
            vim.cmd('startinsert!')
            for i, v in pairs(cfg) do
                vim.api.nvim_buf_set_keymap(term.bufnr, 't', v[1], '<cmd>lua MyToggleTerm(' .. i .. ')<CR>', opts)
                vim.api.nvim_buf_set_keymap(term.bufnr, 'n', v[1], '<cmd>lua MyToggleTerm(' .. i .. ')<CR>', opts)
            end
        end,
    }
end

local term_table = {}

for i, o in pairs(cfg) do
    table.insert(term_table, Terminal:new(make_term(i, o)))
end

local activeTerm = nil

function MyToggleTerm(c)
    local t = term_table[c]
    if activeTerm ~= nil and activeTerm ~= t and activeTerm:is_open() then
        activeTerm:toggle()
    end
    if t:is_open() then
        t:close()
        activeTerm = nil
    else
        t:open()
        vim.cmd('startinsert!')
        activeTerm = t
    end
end

for i, v in pairs(cfg) do
    vim.api.nvim_buf_set_keymap(0, 'n', v[1], '<cmd>lua MyToggleTerm(' .. i .. ')<CR>', opts)
end
