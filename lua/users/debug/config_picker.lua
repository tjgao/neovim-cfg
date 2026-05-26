local launch_json = require("users.debug.launch_json")

local M = {}

local STATE = {
    last_launch = nil,
}

local function clear_last_launch_config()
    STATE.last_launch = nil
end

function M.remember_last_launch_config(config)
    local path = launch_json.get_path()
    local token = launch_json.mtime_token(path)
    if not token then
        clear_last_launch_config()
        return
    end

    STATE.last_launch = {
        config = vim.deepcopy(config),
        token = token,
        path = path,
    }
end

function M.get_valid_last_launch_config()
    local last = STATE.last_launch
    if type(last) ~= "table" or type(last.config) ~= "table" or type(last.path) ~= "string" then
        clear_last_launch_config()
        return nil
    end

    local current_token = launch_json.mtime_token(last.path)
    if not current_token or current_token ~= last.token then
        clear_last_launch_config()
        return nil
    end

    return vim.deepcopy(last.config)
end

function M.setup_cache_invalidation()
    local group = vim.api.nvim_create_augroup("debug-launch-json-cache", { clear = true })
    vim.api.nvim_create_autocmd({ "BufWritePost", "FileChangedShellPost" }, {
        group = group,
        pattern = { "*/.vscode/launch.json", ".vscode/launch.json" },
        callback = function()
            clear_last_launch_config()
        end,
    })
end

local function open_config_editor(dap, selected_config, picker, source_index, picker_item, refresh_picker, opts)
    local sanitized = launch_json.sanitize(vim.deepcopy(selected_config))
    local valid, err = launch_json.validate_config(sanitized)
    if not valid then
        vim.notify(err or "Invalid debug config", vim.log.levels.ERROR)
        return
    end

    local sanitized_table = type(sanitized) == "table" and sanitized or {}
    local lines = vim.split(launch_json.encode_pretty(sanitized_table), "\n", { plain = true })
    local launch_json_path = launch_json.get_path()
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(buf, launch_json_path)
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
        title = " Edit DAP Config JSON ",
        title_pos = "center",
        footer = " :w save  |  R run  |  q close ",
        footer_pos = "center",
    })

    vim.bo[buf].buftype = "acwrite"
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].swapfile = false
    vim.bo[buf].filetype = "json"
    vim.wo[win].wrap = false

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
            pcall(function()
                picker:close()
            end)
        end
    end

    local function run_from_editor(should_save)
        local content = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
        local ok, parsed = pcall(vim.json.decode, content)
        if not ok then
            vim.notify("Invalid JSON: " .. tostring(parsed), vim.log.levels.ERROR)
            return
        end

        local parsed_valid, parsed_err = launch_json.validate_config(parsed)
        if not parsed_valid then
            vim.notify(parsed_err or "Invalid debug config", vim.log.levels.ERROR)
            return
        end

        if should_save then
            if
                not launch_json.save_config(
                    parsed,
                    source_index,
                    launch_json.get_path(),
                    { on_write = clear_last_launch_config }
                )
            then
                return
            end
        end

        close_editor(false)
        close_picker()
        vim.schedule(function()
            opts.run_selected_config(dap, parsed, { remember = should_save })
        end)
    end

    local function save_from_editor()
        local content = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
        local ok, parsed = pcall(vim.json.decode, content)
        if not ok then
            vim.notify("Invalid JSON: " .. tostring(parsed), vim.log.levels.ERROR)
            return
        end

        local parsed_valid, parsed_err = launch_json.validate_config(parsed)
        if not parsed_valid then
            vim.notify(parsed_err or "Invalid debug config", vim.log.levels.ERROR)
            return
        end

        if
            launch_json.save_config(
                parsed,
                source_index,
                launch_json.get_path(),
                { on_write = clear_last_launch_config }
            )
        then
            vim.bo[buf].modified = false

            if picker_item then
                local config_name = type(parsed.name) == "string" and parsed.name or "(unnamed)"
                local config_type = type(parsed.type) == "string" and parsed.type or "?"
                local request = type(parsed.request) == "string" and parsed.request or "?"
                picker_item.item = vim.deepcopy(parsed)
                picker_item.text = ("%s [%s/%s]"):format(config_name, config_type, request)
            end

            if refresh_picker then
                refresh_picker(parsed)
            end
        end
    end

    local opts_map = { buffer = buf, silent = true, nowait = true }
    vim.api.nvim_create_autocmd("BufWriteCmd", {
        buffer = buf,
        callback = save_from_editor,
    })
    vim.keymap.set("n", "q", close_editor, vim.tbl_extend("force", opts_map, { desc = "Close editor" }))
    vim.keymap.set("n", "R", function()
        run_from_editor(false)
    end, vim.tbl_extend("force", opts_map, { desc = "Run edited config" }))
    vim.keymap.set("n", "<S-r>", function()
        run_from_editor(false)
    end, vim.tbl_extend("force", opts_map, { desc = "Run edited config" }))
end

local function default_launch_config()
    return {
        {
            label = "C/C++ (cppdbg + gdb)",
            config = {
                name = "New C/C++ config",
                type = "cppdbg",
                request = "launch",
                program = "${workspaceFolder}/path/to/executable",
                args = {},
                stopAtEntry = false,
                cwd = "${workspaceFolder}",
                environment = {},
                externalConsole = false,
                MIMode = "gdb",
                miDebuggerPath = "/usr/bin/gdb",
                setupCommands = {
                    {
                        description = "Enable pretty printing for gdb",
                        text = "-enable-pretty-printing",
                        ignoreFailures = true,
                    },
                },
            },
        },
        {
            label = "C/C++ or Rust (codelldb)",
            config = {
                name = "New codelldb config",
                type = "codelldb",
                request = "launch",
                program = "${workspaceFolder}/path/to/binary",
                args = {},
                cwd = "${workspaceFolder}",
                stopOnEntry = false,
            },
        },
        {
            label = "Python (launch file)",
            config = {
                name = "New Python config",
                type = "python",
                request = "launch",
                program = "${file}",
                pythonPath = "python3",
                cwd = "${workspaceFolder}",
            },
        },
        {
            label = "Python (launch module)",
            config = {
                name = "New Python module config",
                type = "python",
                request = "launch",
                module = "package.module",
                pythonPath = "python3",
                cwd = "${workspaceFolder}",
            },
        },
        {
            label = "Go (launch current file)",
            config = {
                name = "New Go file config",
                type = "go",
                request = "launch",
                mode = "debug",
                program = "${file}",
                cwd = "${workspaceFolder}",
            },
        },
        {
            label = "Go (launch package)",
            config = {
                name = "New Go package config",
                type = "go",
                request = "launch",
                mode = "debug",
                program = "${workspaceFolder}",
                cwd = "${workspaceFolder}",
            },
        },
        {
            label = "Go (test current file)",
            config = {
                name = "New Go file test config",
                type = "go",
                request = "launch",
                mode = "test",
                program = "${file}",
                cwd = "${workspaceFolder}",
            },
        },
        {
            label = "Go (test package)",
            config = {
                name = "New Go package test config",
                type = "go",
                request = "launch",
                mode = "test",
                program = "${workspaceFolder}",
                cwd = "${workspaceFolder}",
            },
        },
        {
            label = "Go (attach local process)",
            config = {
                name = "New Go attach config",
                type = "go",
                request = "attach",
                mode = "local",
                processId = "${command:PickProcess}",
                cwd = "${workspaceFolder}",
            },
        },
        {
            label = "JavaScript / TypeScript (Node launch)",
            config = {
                name = "New Node launch config",
                type = "pwa-node",
                request = "launch",
                program = "${file}",
                cwd = "${workspaceFolder}",
            },
        },
        {
            label = "JavaScript / TypeScript (Node attach)",
            config = {
                name = "New Node attach config",
                type = "pwa-node",
                request = "attach",
                processId = "${command:PickProcess}",
                cwd = "${workspaceFolder}",
            },
        },
        {
            label = "React (Chrome launch)",
            config = {
                name = "React Chrome",
                type = "pwa-chrome",
                request = "launch",
                url = "http://localhost:3000",
                webRoot = "${workspaceFolder}",
            },
        },
        {
            label = "Svelte (Chrome launch)",
            config = {
                name = "Svelte Chrome",
                type = "pwa-chrome",
                request = "launch",
                url = "http://localhost:5173",
                webRoot = "${workspaceFolder}",
            },
        },
        {
            label = "Svelte (Node launch)",
            config = {
                name = "New Svelte config",
                type = "pwa-node",
                request = "launch",
                program = "${file}",
                cwd = "${workspaceFolder}",
            },
        },
        {
            label = "Empty config",
            config = {
                name = "New config",
                type = "cppdbg",
                request = "launch",
            },
        },
    }
end

local function choose_new_config_template(dap, picker, on_saved, opts)
    local templates = default_launch_config()
    local menu = { "Select debug config template:" }
    for i, template in ipairs(templates) do
        menu[#menu + 1] = ("%d. %s"):format(i, template.label)
    end

    local selected = vim.fn.inputlist(menu)
    local choice = templates[selected]
    if not choice then
        if picker and not picker.closed and type(picker.focus) == "function" then
            picker:focus("list")
        end
        return
    end

    open_config_editor(dap, choice.config, picker, nil, nil, on_saved, opts)
end

local function resolve_debug_configs(dap, callback, opts)
    opts.initialize_debug_backends(dap)

    if launch_json.has(launch_json.get_path()) then
        callback(launch_json.load_dap_configs(launch_json.get_path()))
        return
    end

    callback({})
end

local function show_config_picker(dap, configs, opts)
    local items = {}
    for index, config in ipairs(configs) do
        local name = type(config.name) == "string" and config.name or "(unnamed)"
        local config_type = type(config.type) == "string" and config.type or "?"
        local request = type(config.request) == "string" and config.request or "?"

        items[#items + 1] = {
            text = ("%s [%s/%s]"):format(name, config_type, request),
            item = config,
            source_index = index,
        }
    end

    table.sort(items, function(a, b)
        return a.text < b.text
    end)

    if #items == 0 then
        items[1] = {
            text = "No configs found. Press A to add one",
            item = nil,
            source_index = nil,
            is_placeholder = true,
        }
    end

    local function refresh_picker(picker)
        table.sort(items, function(a, b)
            return a.text < b.text
        end)
        if picker and not picker.closed and type(picker.find) == "function" then
            picker:find()
        end
    end

    local Snacks = require("snacks")
    Snacks.picker.pick({
        source = "select",
        title = "Debug Configs (Enter run, E edit, A add, D delete)",
        focus = "list",
        auto_close = false,
        format = "text",
        preview = "none",
        finder = function()
            return items
        end,
        confirm = function(picker, item)
            if not item then
                return
            end
            if item.is_placeholder then
                choose_new_config_template(dap, picker, nil, opts)
                return
            end
            if not item.item then
                return
            end
            picker:close()
            opts.run_selected_config(dap, item.item)
        end,
        actions = {
            edit_config = function(picker, item)
                if not item or not item.item then
                    return
                end
                open_config_editor(dap, item.item, picker, item.source_index, item, function()
                    refresh_picker(picker)
                end, opts)
            end,
            add_config = function(picker)
                local added_item = nil
                choose_new_config_template(dap, picker, function(parsed)
                    local config_name = type(parsed.name) == "string" and parsed.name or "(unnamed)"
                    local config_type = type(parsed.type) == "string" and parsed.type or "?"
                    local request = type(parsed.request) == "string" and parsed.request or "?"

                    if not added_item then
                        for i = #items, 1, -1 do
                            if items[i].is_placeholder then
                                table.remove(items, i)
                            end
                        end

                        added_item = {
                            text = ("%s [%s/%s]"):format(config_name, config_type, request),
                            item = vim.deepcopy(parsed),
                            source_index = nil,
                        }
                        items[#items + 1] = added_item
                    else
                        added_item.item = vim.deepcopy(parsed)
                        added_item.text = ("%s [%s/%s]"):format(config_name, config_type, request)
                    end

                    refresh_picker(picker)
                end, opts)
            end,
            delete_config = function(picker, item)
                if not item or not item.item then
                    return
                end
                if not launch_json.has(launch_json.get_path()) then
                    vim.notify("Delete is only available for launch.json configs", vim.log.levels.WARN)
                    return
                end

                local config_name = type(item.item.name) == "string" and item.item.name or "(unnamed)"
                local choice = vim.fn.confirm(("Delete config '%s'?"):format(config_name), "&No\n&Yes", 1)
                if choice ~= 2 then
                    return
                end

                if
                    launch_json.delete_config(
                        item.source_index,
                        config_name,
                        launch_json.get_path(),
                        { on_write = clear_last_launch_config }
                    )
                then
                    picker:close()
                    M.open_picker(dap, opts)
                end
            end,
        },
        win = {
            list = {
                keys = {
                    ["E"] = "edit_config",
                    ["A"] = "add_config",
                    ["D"] = "delete_config",
                },
            },
        },
    })
end

function M.open_picker(dap, opts)
    resolve_debug_configs(dap, function(configs)
        show_config_picker(dap, configs, opts)
    end, opts)
end

function M.continue_or_run_single_or_pick(dap, opts)
    if dap.session() then
        dap.continue()
        return
    end

    resolve_debug_configs(dap, function(configs)
        if #configs == 1 then
            opts.run_selected_config(dap, configs[1])
            return
        end

        local remembered = M.get_valid_last_launch_config()
        if remembered then
            opts.run_selected_config(dap, remembered, { remember = false })
            return
        end

        show_config_picker(dap, configs, opts)
    end, opts)
end

return M
