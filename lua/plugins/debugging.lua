local keymap = require("shared.utils").keymap

local DEBUG_SETUP = {
    initialized = false,
    js_enabled = false,
}

local run_selected_config
local open_config_picker

local function find_executable(candidates)
    for _, candidate in ipairs(candidates) do
        if vim.fn.executable(candidate) == 1 then
            return candidate
        end
    end
    return nil
end

local function find_js_debug_adapter()
    local from_path = find_executable({ "js-debug-adapter", "js-debug-adapter.cmd" })
    if from_path then
        return from_path
    end

    local mason_bin = vim.fn.stdpath("data") .. "/mason/bin"
    local candidates = {
        mason_bin .. "/js-debug-adapter",
        mason_bin .. "/js-debug-adapter.cmd",
    }

    for _, candidate in ipairs(candidates) do
        if vim.fn.filereadable(candidate) == 1 and vim.fn.executable(candidate) == 1 then
            return candidate
        end
    end

    return nil
end

local function sanitize_for_json(value)
    local value_type = type(value)
    if value == nil or value_type == "string" or value_type == "number" or value_type == "boolean" then
        return value
    end
    if value_type ~= "table" then
        return nil
    end

    if vim.islist(value) then
        local list = {}
        for _, item in ipairs(value) do
            local sanitized = sanitize_for_json(item)
            if sanitized ~= nil then
                list[#list + 1] = sanitized
            end
        end
        return list
    end

    local object = {}
    for key, item in pairs(value) do
        if type(key) == "string" then
            local sanitized = sanitize_for_json(item)
            if sanitized ~= nil then
                object[key] = sanitized
            end
        end
    end
    return object
end

local function encode_json_pretty(value, depth)
    depth = depth or 0
    local value_type = type(value)

    if value == nil then
        return "null"
    end
    if value_type == "string" then
        return vim.json.encode(value)
    end
    if value_type == "number" or value_type == "boolean" then
        return tostring(value)
    end
    if value_type ~= "table" then
        return "null"
    end

    local indent = string.rep("  ", depth)
    local child_indent = string.rep("  ", depth + 1)

    if vim.islist(value) then
        if #value == 0 then
            return "[]"
        end

        local parts = {}
        for _, item in ipairs(value) do
            parts[#parts + 1] = child_indent .. encode_json_pretty(item, depth + 1)
        end

        return "[\n" .. table.concat(parts, ",\n") .. "\n" .. indent .. "]"
    end

    local keys = vim.tbl_keys(value)
    table.sort(keys)
    if #keys == 0 then
        return "{}"
    end

    local parts = {}
    for _, key in ipairs(keys) do
        parts[#parts + 1] = child_indent .. vim.json.encode(key) .. ": " .. encode_json_pretty(value[key], depth + 1)
    end

    return "{\n" .. table.concat(parts, ",\n") .. "\n" .. indent .. "}"
end

local function validate_debug_config(config)
    if type(config) ~= "table" then
        return false, "Configuration must be a JSON object"
    end

    local required = { "name", "type", "request" }
    for _, field in ipairs(required) do
        if type(config[field]) ~= "string" or config[field] == "" then
            return false, ("Configuration requires a non-empty '%s' field"):format(field)
        end
    end

    return true
end

local function get_launch_json_path()
    return vim.fn.getcwd() .. "/.vscode/launch.json"
end

local function read_launch_json(path)
    if vim.fn.filereadable(path) == 0 then
        return {
            version = "0.2.0",
            configurations = {},
        }
    end

    local file = io.open(path, "r")
    if not file then
        return nil, ("Could not open %s for reading"):format(path)
    end
    local content = file:read("*a")
    file:close()

    local ok, parsed = pcall(vim.json.decode, content)
    if not ok then
        return nil, ("Invalid JSON in %s: %s"):format(path, parsed)
    end
    if type(parsed) ~= "table" then
        return nil, ("Invalid JSON in %s: root must be an object"):format(path)
    end

    if type(parsed.configurations) ~= "table" then
        parsed.configurations = {}
    end
    if type(parsed.version) ~= "string" or parsed.version == "" then
        parsed.version = "0.2.0"
    end

    return parsed
end

local function write_launch_json(path, launch)
    local directory = vim.fn.fnamemodify(path, ":h")
    if vim.fn.isdirectory(directory) == 0 then
        vim.fn.mkdir(directory, "p")
    end

    local serialized = encode_json_pretty(launch) .. "\n"
    local file, open_err = io.open(path, "w")
    if not file then
        vim.notify(
            ("Could not open %s for writing: %s"):format(path, open_err or "unknown error"),
            vim.log.levels.ERROR
        )
        return false
    end

    file:write(serialized)
    file:close()
    return true
end

local function save_config_to_launch_json(config, previous_index)
    local path = get_launch_json_path()
    local launch, read_err = read_launch_json(path)
    if not launch then
        vim.notify(read_err or "Failed to read launch.json", vim.log.levels.ERROR)
        return false
    end

    local configurations = launch.configurations
    local replaced = false
    if type(previous_index) == "number" and previous_index >= 1 and previous_index <= #configurations then
        configurations[previous_index] = vim.deepcopy(config)
        replaced = true
    end

    if not replaced then
        configurations[#configurations + 1] = vim.deepcopy(config)
    end

    if not write_launch_json(path, launch) then
        return false
    end

    vim.notify(("Saved debug configuration '%s' to %s"):format(config.name, path), vim.log.levels.INFO)
    return true
end

local function delete_config_from_launch_json(source_index, fallback_name)
    local path = get_launch_json_path()
    local launch, read_err = read_launch_json(path)
    if not launch then
        vim.notify(read_err or "Failed to read launch.json", vim.log.levels.ERROR)
        return false
    end

    local configurations = launch.configurations
    local removed = false
    if type(source_index) == "number" and source_index >= 1 and source_index <= #configurations then
        table.remove(configurations, source_index)
        removed = true
    elseif type(fallback_name) == "string" and fallback_name ~= "" then
        for i, item in ipairs(configurations) do
            if type(item) == "table" and item.name == fallback_name then
                table.remove(configurations, i)
                removed = true
                break
            end
        end
    end

    if not removed then
        vim.notify("Could not find config to delete", vim.log.levels.WARN)
        return false
    end

    if not write_launch_json(path, launch) then
        return false
    end

    vim.notify("Deleted debug configuration", vim.log.levels.INFO)
    return true
end

local function open_config_editor(dap, selected_config, picker, source_index, picker_item, refresh_picker)
    local sanitized = sanitize_for_json(vim.deepcopy(selected_config))
    local valid, err = validate_debug_config(sanitized)
    if not valid then
        vim.notify(err or "Invalid debug config", vim.log.levels.ERROR)
        return
    end

    local sanitized_table = type(sanitized) == "table" and sanitized or {}
    local lines = vim.split(encode_json_pretty(sanitized_table), "\n", { plain = true })
    local launch_json_path = get_launch_json_path()
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

        local parsed_valid, parsed_err = validate_debug_config(parsed)
        if not parsed_valid then
            vim.notify(parsed_err or "Invalid debug config", vim.log.levels.ERROR)
            return
        end

        if should_save then
            if not save_config_to_launch_json(parsed, source_index) then
                return
            end
        end

        close_editor(false)
        close_picker()
        vim.schedule(function()
            run_selected_config(dap, parsed)
        end)
    end

    local function save_from_editor()
        local content = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
        local ok, parsed = pcall(vim.json.decode, content)
        if not ok then
            vim.notify("Invalid JSON: " .. tostring(parsed), vim.log.levels.ERROR)
            return
        end

        local parsed_valid, parsed_err = validate_debug_config(parsed)
        if not parsed_valid then
            vim.notify(parsed_err or "Invalid debug config", vim.log.levels.ERROR)
            return
        end

        if save_config_to_launch_json(parsed, source_index) then
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

    local opts = { buffer = buf, silent = true, nowait = true }
    vim.api.nvim_create_autocmd("BufWriteCmd", {
        buffer = buf,
        callback = save_from_editor,
    })
    vim.keymap.set("n", "q", close_editor, vim.tbl_extend("force", opts, { desc = "Close editor" }))
    vim.keymap.set("n", "R", function()
        run_from_editor(false)
    end, vim.tbl_extend("force", opts, { desc = "Run edited config" }))
    vim.keymap.set("n", "<S-r>", function()
        run_from_editor(false)
    end, vim.tbl_extend("force", opts, { desc = "Run edited config" }))
end

local function setup_js_adapter()
    local js_debug_adapter = find_js_debug_adapter()
    if not js_debug_adapter then
        vim.notify(
            "js-debug-adapter not found (install 'js' via Mason and ensure Mason bin is executable)",
            vim.log.levels.WARN
        )
        return false
    end

    require("dap-vscode-js").setup({
        debugger_cmd = { js_debug_adapter },
        adapters = {
            "pwa-node",
            "pwa-chrome",
            "pwa-msedge",
            "node-terminal",
            "pwa-extensionHost",
        },
    })
    return true
end

local function setup_gdb_adapter(dap)
    local gdb = find_executable({ "gdb" })
    if not gdb then
        return false
    end

    dap.adapters.gdb = {
        type = "executable",
        command = gdb,
        args = { "--interpreter=dap", "--silent" },
    }
    return true
end

local function adapter_is_configured(dap, adapter_name)
    return dap.adapters and dap.adapters[adapter_name] ~= nil
end

local function initialize_debug_backends(dap)
    if DEBUG_SETUP.initialized then
        return
    end

    DEBUG_SETUP.js_enabled = setup_js_adapter()
    setup_gdb_adapter(dap)

    DEBUG_SETUP.initialized = true
end

local function prepare_config_for_run(dap, config)
    local runnable = vim.deepcopy(config)

    local adapter_checks = {
        cppdbg = "cppdbg adapter is not available (install cpptools via Mason)",
        codelldb = "codelldb adapter is not available",
        gdb = "gdb adapter is not available",
        go = "go adapter is not available (install delve via Mason)",
        python = "python adapter is not available (install debugpy via Mason)",
        ["pwa-node"] = "js-debug-adapter is not available",
        ["pwa-chrome"] = "js-debug-adapter is not available",
        ["pwa-msedge"] = "js-debug-adapter is not available",
    }

    local error_message = adapter_checks[runnable.type]
    if error_message and not adapter_is_configured(dap, runnable.type) then
        return nil, error_message
    end

    return runnable
end

run_selected_config = function(dap, config)
    initialize_debug_backends(dap)
    local runnable, err = prepare_config_for_run(dap, config)
    if not runnable then
        vim.notify(err or "Debug config cannot run", vim.log.levels.ERROR)
        return
    end
    dap.run(runnable)
end

local function load_launch_json_configs()
    local path = get_launch_json_path()
    local ok, configs_or_err = pcall(function()
        return require("dap.ext.vscode").getconfigs(path)
    end)

    if not ok then
        vim.notify("Failed loading launch.json configs: " .. tostring(configs_or_err), vim.log.levels.WARN)
        return {}
    end

    return configs_or_err or {}
end

local function has_launch_json()
    return vim.fn.filereadable(get_launch_json_path()) == 1
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

local function choose_new_config_template(dap, picker, on_saved)
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

    open_config_editor(dap, choice.config, picker, nil, nil, on_saved)
end

local function resolve_debug_configs(dap, callback)
    initialize_debug_backends(dap)

    if has_launch_json() then
        callback(load_launch_json_configs())
        return
    end

    callback({})
end

local function show_config_picker(dap, configs)
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
                choose_new_config_template(dap, picker)
                return
            end
            if not item.item then
                return
            end
            picker:close()
            run_selected_config(dap, item.item)
        end,
        actions = {
            edit_config = function(picker, item)
                if not item or not item.item then
                    return
                end
                open_config_editor(dap, item.item, picker, item.source_index, item, function()
                    refresh_picker(picker)
                end)
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
                end)
            end,
            delete_config = function(picker, item)
                if not item or not item.item then
                    return
                end
                if not has_launch_json() then
                    vim.notify("Delete is only available for launch.json configs", vim.log.levels.WARN)
                    return
                end

                local config_name = type(item.item.name) == "string" and item.item.name or "(unnamed)"
                local choice = vim.fn.confirm(("Delete config '%s'?"):format(config_name), "&No\n&Yes", 1)
                if choice ~= 2 then
                    return
                end

                if delete_config_from_launch_json(item.source_index, config_name) then
                    picker:close()
                    open_config_picker(dap)
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

open_config_picker = function(dap)
    resolve_debug_configs(dap, function(configs)
        show_config_picker(dap, configs)
    end)
end

local function continue_or_run_single_or_pick(dap)
    if dap.session() then
        dap.continue()
        return
    end

    resolve_debug_configs(dap, function(configs)
        if #configs == 1 then
            run_selected_config(dap, configs[1])
            return
        end

        show_config_picker(dap, configs)
    end)
end

local function setup_ui_listeners(dap, dapview)
    dap.listeners.before.attach.dapui_config = function()
        dapview.open()
    end
    dap.listeners.before.launch.dapui_config = function()
        dapview.open()
    end
    dap.listeners.before.event_terminated.dapui_config = function()
        dapview.close()
    end
    dap.listeners.before.event_exited.dapui_config = function()
        dapview.close()
    end
end

local function setup_keymaps(dap)
    local break_cond = function()
        dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
    end
    local break_hit = function()
        dap.set_breakpoint(nil, vim.fn.input("Hit condition (e.g. 10 or > 10): "))
    end

    keymap("n", "<Leader>db", dap.toggle_breakpoint, { desc = "Toggle breakpoint<F9>" })
    keymap("n", "<Leader>dB", break_cond, { desc = "Set breakpoint with value condition" })
    keymap("n", "<leader>dH", break_hit, { desc = "Set breakpoint with hit condition" })

    keymap("n", "<F5>", function()
        continue_or_run_single_or_pick(dap)
    end, { desc = "Start/Continue" })
    keymap("n", "<F11>", dap.step_into, { desc = "Step into" })
    keymap("n", "<F10>", dap.step_over, { desc = "Step over" })
    keymap("n", "<F9>", dap.toggle_breakpoint, { desc = "Toggle breakpoint" })
    keymap("n", "<S-F11>", dap.step_out, { desc = "Step out" })
    keymap("n", "<F23>", dap.step_out, { desc = "Step out (Shift-F11 in terminal)" })

    keymap("n", "<Leader>dc", function()
        if dap.session() then
            dap.continue()
            return
        end
        open_config_picker(dap)
    end, { desc = "Continue or pick config" })
    keymap("n", "<Leader>di", dap.step_into, { desc = "Step into<F11>" })
    keymap("n", "<Leader>do", dap.step_out, { desc = "Step out<S-F11>" })
    keymap("n", "<Leader>dv", dap.step_over, { desc = "Step over<F10>" })
end

return {
    "mfussenegger/nvim-dap",
    dependencies = {
        {
            "igorlfs/nvim-dap-view",
            version = "1.*",
            opts = {},
        },
        "jay-babu/mason-nvim-dap.nvim",
        "leoluz/nvim-dap-go",
        "mxsdev/nvim-dap-vscode-js",
    },
    config = function()
        local dap = require("dap")
        local dapview = require("dap-view")

        local mason_dap = require("mason-nvim-dap")
        mason_dap.setup({
            ensure_installed = {
                "cppdbg",
                "codelldb",
                "delve",
                "js",
                "python",
            },
            automatic_installation = true,
            handlers = {},
        })

        dapview.setup()
        require("dap-go").setup()

        setup_ui_listeners(dap, dapview)
        setup_keymaps(dap)
        keymap("n", "<Leader>dx", function()
            dap.terminate()
            dapview.close()
        end, { desc = "Exit debugger" })
    end,
}
