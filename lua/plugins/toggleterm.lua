function _G.set_terminal_keymaps()
    vim.api.nvim_buf_set_keymap(0, "t", "<c-\\>", [[<c-\><c-n>]], { noremap = true })
end

vim.cmd("autocmd! TermOpen term://* lua set_terminal_keymaps()")

local keymap_opts = { noremap = true, silent = true }

-- If we need some command to run in the opened terminal
-- { name = "F10", key = "<F10>", direction = "float",      szie = 0,     cmd = 'cmd="lazygit"' },
local cfg = {
    { name = "F2", key = "<F2>", direction = "float", size = 0, cmd = "" },
    { name = "F3", key = "<F3>", direction = "float", szie = 0, cmd = "" },
    { name = "F4", key = "<F4>", direction = "horizontal", size = vim.o.lines * 0.35, cmd = "" },
}

local make_term = function(idx, o)
    return {
        count = idx,
        direction = o.direction,
        display_name = o.name,
        float_opts = {
            border = "curved",
        },
        close_on_exit = true, -- close the terminal window when the process exits
        start_in_insert = true,

        size = function(term)
            if term.direction == "horizontal" then
                return 30
            elseif term.direction == "vertical" then
                return vim.o.columns * 0.4
            end
        end,

        on_open = function(_)
            vim.cmd("startinsert")
        end,

        on_create = function(term)
            vim.api.nvim_buf_set_keymap(term.bufnr, "t", o.key, "<cmd>lua MyToggleTerm(" .. idx .. ")<CR>", keymap_opts)
            if o.cmd ~= nil and o.cmd ~= "" then
                require("toggleterm").exec_command(o.cmd, idx)
            end
        end,
    }
end

M = {
    "akinsho/toggleterm.nvim",
    branch = "main",
    config = function()
        -- local utils = require("toggleterm.utils")
        local terminal = require("toggleterm.terminal").Terminal
        local toggleterm = require("toggleterm")
        toggleterm.setup()
        local term_table = {}

        for i, o in pairs(cfg) do
            table.insert(term_table, terminal:new(make_term(i, o)))
        end

        function MyToggleTerm(c)
            local t = term_table[c]
            if t ~= nil then
                t:toggle(cfg[c].size, cfg[c].direction)
            end
            if cfg[c].cmd ~= nil and cfg[c].cmd ~= "" then
                toggleterm.exec_command(cfg[c].cmd, c)
            end
        end

        function MyToggleTermRun(c)
            -- We must get visual selection first
            -- if we call MyToggleTerm, we lose visual selection
            local cmd = require("shared.utils").get_visual_selection()
            MyToggleTerm(c)
            if term_table[c] ~= nil and cmd ~= "" then
                toggleterm.exec(cmd, c)
            end
        end

        for _, mode in pairs({ "i", "n", "v" }) do
            for i, v in pairs(cfg) do
                vim.keymap.set(mode, v.key, function()
                    MyToggleTerm(i)
                end, keymap_opts)
            end
        end
    end,
}

return M
