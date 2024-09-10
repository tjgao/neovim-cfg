function _G.set_terminal_keymaps()
    local opts = { noremap = true }
    vim.api.nvim_buf_set_keymap(0, "t", "<c-\\>", [[<c-\><c-n>]], opts)
end

vim.cmd("autocmd! TermOpen term://* lua set_terminal_keymaps()")

local opts = { noremap = true, silent = true }

local cfg = {
    { "<F9>", "float", 0, "" },
    { "<F10>", "float", 0, "" },
    { "<F11>", "float", 0, "" },
    { "<F12>", "horizontal", vim.o.lines * 0.35, "" },
    -- { "<F10>", "float", 'cmd="lazygit"' },
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
                return 30
            elseif term.direction == "vertical" then
                return vim.o.columns * 0.4
            end
        end,

        on_open = function(_)
            vim.cmd("startinsert")
        end,

        on_create = function(term)
            vim.api.nvim_buf_set_keymap(term.bufnr, "t", o[1], "<cmd>lua MyToggleTerm(" .. idx .. ")<CR>", opts)
            if o[4] ~= nil and o[4] ~= "" then
                require("toggleterm").exec_command(o[4], idx)
            end
        end,
    }
end

local function get_visual_selection()
    local s_start = vim.fn.getpos("'<")
    local s_end = vim.fn.getpos("'>")
    local n_lines = math.abs(s_end[2] - s_start[2]) + 1
    local lines = vim.api.nvim_buf_get_lines(0, s_start[2] - 1, s_end[2], false)
    lines[n_lines] = string.sub(lines[n_lines], 1, s_end[3])
    lines[1] = string.sub(lines[1], s_start[3], -1)
    return table.concat(lines, "\n")
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
                local dir = cfg[c][2]
                if dir == "horizontal" or dir == "vertical" then
                    t:toggle(cfg[c][3], dir)
                else
                    t:toggle()
                end
            end
        end

        function MyToggleTermRun(c)
            -- We must get visual selection first
            -- if we call MyToggleTerm, we lose visual selection
            local cmd = get_visual_selection()
            MyToggleTerm(c)
            if cmd ~= "" then
                require("toggleterm").exec(cmd, c)
            end
        end

        for i, v in pairs(cfg) do
            vim.keymap.set("i", v[1], "<cmd>lua MyToggleTerm(" .. i .. ")<CR>", opts)
            vim.keymap.set("n", v[1], ":lua MyToggleTerm(" .. i .. ")<CR>", opts)
            vim.keymap.set("v", v[1], ":lua MyToggleTermRun(" .. i .. ")<CR>", opts)
        end
    end,
}

return M
