function _G.set_terminal_keymaps()
    vim.api.nvim_buf_set_keymap(0, "t", "<c-\\>", [[<c-\><c-n>]], { noremap = true })
end

vim.cmd("autocmd! TermOpen term://* lua set_terminal_keymaps()")

local keymap_opts = { noremap = true, silent = true }

local cfg = {
    { name = "F9",  key = "<F9>",  direction = "float",      size = 0,                  cmd = "" },
    { name = "F10", key = "<F10>", direction = "float",      szie = 0,                  cmd = "" },
    { name = "F11", key = "<F11>", direction = "float",      size = 0,                  cmd = "" },
    { name = "F12", key = "<F12>", direction = "horizontal", size = vim.o.lines * 0.35, cmd = "" },
    -- { name = "F10", key = "<F10>", direction = "float",      szie = 0,               cmd = 'cmd="lazygit"' },
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

-- local function send_to_terminal(selection_type)
--     local terminals = terminal.get_all(true)
--     if #terminals == 0 then
--         return utils.notify("No toggleterms are open yet", "info")
--     end
--     if #terminals == 1 then
--         toggleterm.send_lines_to_terminal(selection_type, true, terminals[1].id)
--         return
--     end
--     vim.ui.select(terminals, {
--         prompt = "Please select a terminal to open (or focus): ",
--         format_item = function(term)
--             return term.id .. ": " .. term:_display_name()
--         end,
--     }, function(_, idx)
--         local term = terminals[idx]
--         if not term then
--             return
--         end
--         if term:is_open() then
--             term:focus()
--         else
--             term:open()
--         end
--     end)
-- end

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

        for i, v in pairs(cfg) do
            vim.keymap.set("i", v.key, "<cmd>lua MyToggleTerm(" .. i .. ")<CR>", keymap_opts)
            vim.keymap.set("n", v.key, ":lua MyToggleTerm(" .. i .. ")<CR>", keymap_opts)
            vim.keymap.set("v", v.key, ":lua MyToggleTermRun(" .. i .. ")<CR>", keymap_opts)
        end
    end,
}

return M
