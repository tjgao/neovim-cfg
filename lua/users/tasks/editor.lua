local tasks_json = require("users.tasks.json")

local M = {}

function M.open_task_editor(selected_task, picker, source_index, picker_item, refresh_picker, opts)
    opts = opts or {}

    local sanitized = tasks_json.sanitize_for_json(vim.deepcopy(selected_task))
    local valid, err = tasks_json.validate_task(sanitized)
    if not valid then
        vim.notify(err or "Invalid task", vim.log.levels.ERROR)
        return
    end

    local sanitized_table = type(sanitized) == "table" and sanitized or {}
    local lines = vim.split(tasks_json.encode_json_pretty(sanitized_table), "\n", { plain = true })
    local tasks_json_path = tasks_json.get_tasks_json_path()
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(buf, tasks_json_path)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

    local width = math.min(math.floor(vim.o.columns * 0.75), 110)
    local height = math.min(math.floor(vim.o.lines * 0.75), 32)
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)
    local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        style = "minimal",
        border = "single",
        width = width,
        height = height,
        row = row,
        col = col,
        title = " Edit Task JSON ",
        title_pos = "center",
        footer = " :w save  |  R run  |  q close ",
        footer_pos = "center",
    })

    vim.bo[buf].buftype = "acwrite"
    vim.bo[buf].swapfile = false
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].modifiable = true
    vim.bo[buf].filetype = "json"
    vim.bo[buf].undofile = false
    vim.wo[win].winblend = 0

    local picker_hidden = false
    if picker and picker.layout and type(picker.layout.hide) == "function" then
        local ok = pcall(function()
            picker.layout:hide()
        end)
        picker_hidden = ok
    end

    local function close_editor(restore_picker)
        if restore_picker == nil then
            restore_picker = true
        end

        if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_close(win, true)
        end

        if
            restore_picker
            and picker_hidden
            and picker
            and not picker.closed
            and picker.layout
            and type(picker.layout.unhide) == "function"
        then
            pcall(function()
                picker.layout:unhide()
            end)
            vim.schedule(function()
                if picker and not picker.closed and type(picker.focus) == "function" then
                    pcall(function()
                        picker:focus("list")
                    end)
                end
            end)
        end
    end

    local function close_picker()
        if picker and type(picker.close) == "function" then
            picker:close()
        end
    end

    local function parse_editor_task()
        local content = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
        local ok, parsed = pcall(vim.json.decode, content)
        if not ok then
            vim.notify("Invalid JSON: " .. tostring(parsed), vim.log.levels.ERROR)
            return nil
        end

        local parsed_valid, parsed_err = tasks_json.validate_task(parsed)
        if not parsed_valid then
            vim.notify(parsed_err or "Invalid task", vim.log.levels.ERROR)
            return nil
        end

        return parsed
    end

    local function save_from_editor()
        local parsed = parse_editor_task()
        if not parsed then
            return false
        end

        if tasks_json.save_task_to_tasks_json(parsed, source_index) then
            vim.bo[buf].modified = false

            if picker_item then
                local label = type(parsed.label) == "string" and parsed.label or "(unlabeled)"
                local task_type = type(parsed.type) == "string" and parsed.type or "?"
                local command = type(parsed.command) == "string" and parsed.command or "(no command)"
                picker_item.item = vim.deepcopy(parsed)
                picker_item.text = ("%s [%s] %s"):format(label, task_type, command)

                local tasks_doc = tasks_json.read_tasks_json(tasks_json.get_tasks_json_path())
                if tasks_doc then
                    picker_item.source_index = tasks_json.find_task_index_by_label(tasks_doc.tasks, label)
                end
            end

            if refresh_picker then
                refresh_picker(parsed)
            end

            return true, parsed
        end

        return false
    end

    local function run_from_editor()
        local did_save, parsed = save_from_editor()
        if not did_save or not parsed then
            return
        end

        close_editor(false)
        close_picker()
        vim.schedule(function()
            opts.run_task_by_label(parsed.label, source_index)
        end)
    end

    local opts_map = { buffer = buf, silent = true, nowait = true }
    vim.api.nvim_create_autocmd("BufWriteCmd", {
        buffer = buf,
        callback = save_from_editor,
    })
    vim.keymap.set("n", "q", close_editor, vim.tbl_extend("force", opts_map, { desc = "Close editor" }))
    vim.keymap.set("n", "R", run_from_editor, vim.tbl_extend("force", opts_map, { desc = "Save and run task" }))
    vim.keymap.set("n", "<S-r>", run_from_editor, vim.tbl_extend("force", opts_map, { desc = "Save and run task" }))
end

return M
