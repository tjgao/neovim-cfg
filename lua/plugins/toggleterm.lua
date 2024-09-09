function _G.set_terminal_keymaps()
    local opts = { noremap = true }
    vim.api.nvim_buf_set_keymap(0, "t", "<c-\\>", [[<c-\><c-n>]], opts)
end

vim.cmd("autocmd! TermOpen term://* lua set_terminal_keymaps()")

local opts = { noremap = true, silent = true }

local cfg = {
    { "<F9>",  "float",      "" },
    { "<F10>", "float",      "" },
    -- { "<F10>", "float", 'cmd="lazygit"' },
    { "<F11>", "float",      "" },
    { "<F12>", "horizontal", "" },
}

local make_term = function(idx, o)
    return {
        count = idx,
        direction = o[2],
        float_opts = {
            border = "curved",
        },
        close_on_exit = true, -- close the terminal window when the process exits
        start_in_insert = true,

        size = function(term)
            if term.direction == "horizontal" then
                return 80
            elseif term.direction == "vertical" then
                return vim.o.columns * 0.4
            end
        end,

        on_open = function(_)
            vim.cmd("startinsert")
        end,

        on_create = function(term)
            vim.api.nvim_buf_set_keymap(term.bufnr, "t", o[1], "<cmd>lua MyToggleTerm(" .. idx .. ")<CR>", opts)
            if o[3] ~= nil and o[3] ~= "" then
                require("toggleterm").exec_command(o[3], idx)
            end
        end,
    }
end

M = {
    "akinsho/toggleterm.nvim",
    branch = "main",
    config = function()
        local Terminal = require("toggleterm.terminal").Terminal
        local term_table = {}

        for i, o in pairs(cfg) do
            table.insert(term_table, Terminal:new(make_term(i, o)))
        end

        function MyToggleTerm(c)
            local t = term_table[c]
            if t ~= nil then
                t:toggle()
            end
        end

        for i, v in pairs(cfg) do
            vim.keymap.set("i", v[1], "<cmd>lua MyToggleTerm(" .. i .. ")<CR>", opts)
            vim.keymap.set("n", v[1], ":lua MyToggleTerm(" .. i .. ")<CR>", opts)
        end
    end,
}

return M
