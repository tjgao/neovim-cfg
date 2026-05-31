local M = {}

local MESSAGE_VIEW = {
    buf = nil,
    win = nil,
    ns = vim.api.nvim_create_namespace("messages-view"),
}

local function render_messages(buf)
    local output = vim.api.nvim_exec2("messages", { output = true }).output or ""
    local lines = vim.split(output, "\n", { plain = true })
    if #lines == 0 or (#lines == 1 and lines[1] == "") then
        lines = { "(no messages)" }
    end

    local was_readonly = vim.bo[buf].readonly
    vim.bo[buf].readonly = false
    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_buf_clear_namespace(buf, MESSAGE_VIEW.ns, 0, -1)

    for i, line in ipairs(lines) do
        local lower = line:lower()
        local hl = nil
        if line:match("^E%d+") or lower:find("error", 1, true) then
            hl = "ErrorMsg"
        elseif line:match("^W%d+") or lower:find("warning", 1, true) or lower:find("warn", 1, true) then
            hl = "WarningMsg"
        elseif lower:find("info", 1, true) or lower:find("note", 1, true) then
            hl = "DiagnosticInfo"
        end

        if hl then
            vim.api.nvim_buf_set_extmark(buf, MESSAGE_VIEW.ns, i - 1, 0, {
                end_row = i,
                end_col = 0,
                hl_group = hl,
                hl_eol = true,
            })
        end
    end

    vim.bo[buf].modifiable = false
    vim.bo[buf].readonly = was_readonly
end

function M.open_messages_window()
    local buf = MESSAGE_VIEW.buf
    if not (buf and vim.api.nvim_buf_is_valid(buf)) then
        buf = vim.api.nvim_create_buf(false, true)
        MESSAGE_VIEW.buf = buf
        vim.bo[buf].buftype = "nofile"
        vim.bo[buf].bufhidden = "wipe"
        vim.bo[buf].swapfile = false
        vim.bo[buf].filetype = "log"
        vim.bo[buf].readonly = true
    end

    local win = MESSAGE_VIEW.win
    if not (win and vim.api.nvim_win_is_valid(win)) then
        local width = math.min(math.floor(vim.o.columns * 0.8), 140)
        local height = math.min(math.floor(vim.o.lines * 0.7), 40)
        local row = math.floor((vim.o.lines - height) / 2)
        local col = math.floor((vim.o.columns - width) / 2)
        win = vim.api.nvim_open_win(buf, true, {
            relative = "editor",
            style = "minimal",
            border = "single",
            width = width,
            height = height,
            row = row,
            col = col,
            title = " Messages ",
            title_pos = "center",
            footer = " q close  |  R refresh ",
            footer_pos = "center",
        })
        MESSAGE_VIEW.win = win

        vim.api.nvim_create_autocmd("WinClosed", {
            once = true,
            pattern = tostring(win),
            callback = function()
                MESSAGE_VIEW.win = nil
                MESSAGE_VIEW.buf = nil
            end,
        })

        local opts = { buffer = buf, silent = true, nowait = true }
        vim.keymap.set("n", "q", function()
            if MESSAGE_VIEW.win and vim.api.nvim_win_is_valid(MESSAGE_VIEW.win) then
                vim.api.nvim_win_close(MESSAGE_VIEW.win, true)
            end
        end, vim.tbl_extend("force", opts, { desc = "Close messages" }))
        vim.keymap.set("n", "R", function()
            if MESSAGE_VIEW.buf and vim.api.nvim_buf_is_valid(MESSAGE_VIEW.buf) then
                render_messages(MESSAGE_VIEW.buf)
            end
        end, vim.tbl_extend("force", opts, { desc = "Refresh messages" }))
    else
        vim.api.nvim_set_current_win(win)
    end

    render_messages(buf)
end

function M.setup()
    vim.api.nvim_create_user_command("M", M.open_messages_window, { desc = "Open messages viewer" })
    vim.api.nvim_create_user_command("Mess", M.open_messages_window, { desc = "Open messages viewer" })
    vim.api.nvim_create_user_command("Message", M.open_messages_window, { desc = "Open messages viewer" })
end

return M
