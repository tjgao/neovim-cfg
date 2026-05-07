local keymap = require("shared.utils").keymap

local JS_FILETYPES = {
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact",
    "svelte",
}

local function find_executable(candidates)
    for _, candidate in ipairs(candidates) do
        if vim.fn.executable(candidate) == 1 then
            return candidate
        end
    end
    return nil
end

local function python_path()
    local venv = os.getenv("VIRTUAL_ENV")
    if venv and venv ~= "" then
        local venv_python = venv .. "/bin/python"
        if vim.fn.executable(venv_python) == 1 then
            return venv_python
        end
    end

    local cwd = vim.fn.getcwd()
    local candidates = {
        cwd .. "/.venv/bin/python",
        cwd .. "/venv/bin/python",
        cwd .. "/.python-venv/bin/python",
        "python3",
        "python",
    }

    return find_executable(candidates) or "python3"
end

local function default_program()
    return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
end

local function split_shell_words(input)
    local words = {}
    local current = {}
    local quote = nil
    local escaped = false

    for i = 1, #input do
        local ch = input:sub(i, i)
        if escaped then
            current[#current + 1] = ch
            escaped = false
        elseif ch == "\\" then
            escaped = true
        elseif quote then
            if ch == quote then
                quote = nil
            else
                current[#current + 1] = ch
            end
        elseif ch == '"' or ch == "'" then
            quote = ch
        elseif ch:match("%s") then
            if #current > 0 then
                words[#words + 1] = table.concat(current)
                current = {}
            end
        else
            current[#current + 1] = ch
        end
    end

    if #current > 0 then
        words[#words + 1] = table.concat(current)
    end

    return words
end

local function config_command(config)
    local program = config.program
    if type(program) == "function" then
        local ok, value = pcall(program)
        program = ok and value or ""
    end
    if type(program) ~= "string" then
        program = ""
    end

    local args = config.args or {}
    if type(args) == "string" then
        args = { args }
    end

    local parts = {}
    if program ~= "" then
        parts[#parts + 1] = vim.fn.shellescape(program)
    end
    for _, arg in ipairs(args) do
        parts[#parts + 1] = vim.fn.shellescape(arg)
    end
    return table.concat(parts, " ")
end

local function setup_js_adapter()
    local js_debug_adapter = find_executable({ "js-debug-adapter", "js-debug-adapter.cmd" })
    if not js_debug_adapter then
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

local function setup_codelldb(dap)
    local codelldb = find_executable({ "codelldb" })
    if codelldb then
        dap.adapters.codelldb = {
            type = "server",
            port = "${port}",
            executable = {
                command = codelldb,
                args = { "--port", "${port}" },
            },
        }
    end
    return codelldb ~= nil
end

local function setup_cpp_configs(dap, has_codelldb)
    local adapter_type = has_codelldb and "codelldb" or "cppdbg"
    local cpp_configs = {
        {
            name = "Launch executable",
            type = adapter_type,
            request = "launch",
            program = default_program,
            cwd = "${workspaceFolder}",
            stopOnEntry = false,
        },
        {
            name = "Launch executable (with args)",
            type = adapter_type,
            request = "launch",
            program = default_program,
            args = function()
                return vim.split(vim.fn.input("Arguments: "), " ", { trimempty = true })
            end,
            cwd = "${workspaceFolder}",
            stopOnEntry = false,
        },
    }

    dap.configurations.cpp = dap.configurations.cpp or cpp_configs
    dap.configurations.c = dap.configurations.c or vim.deepcopy(cpp_configs)
    dap.configurations.rust = dap.configurations.rust or vim.deepcopy(cpp_configs)
end

local function setup_python_configs(dap)
    require("dap-python").setup(python_path())
    dap.configurations.python = dap.configurations.python or {
        {
            type = "python",
            request = "launch",
            name = "Launch current file",
            program = "${file}",
            pythonPath = python_path,
            cwd = "${workspaceFolder}",
        },
        {
            type = "python",
            request = "launch",
            name = "Launch module",
            module = function()
                return vim.fn.input("Python module: ")
            end,
            pythonPath = python_path,
            cwd = "${workspaceFolder}",
        },
    }
end

local function setup_js_configs(dap)
    local js_configs = {
        {
            type = "pwa-node",
            request = "launch",
            name = "Launch current file (Node)",
            program = "${file}",
            cwd = "${workspaceFolder}",
        },
        {
            type = "pwa-node",
            request = "attach",
            name = "Attach to process (Node)",
            processId = require("dap.utils").pick_process,
            cwd = "${workspaceFolder}",
        },
    }

    for _, ft in ipairs(JS_FILETYPES) do
        dap.configurations[ft] = dap.configurations[ft] or vim.deepcopy(js_configs)
    end
end

local function collect_configs(dap, bufnr, callback)
    require("dap.async").run(function()
        local configs = {}
        for _, get_configs in pairs(dap.providers.configs) do
            local provided = get_configs(bufnr) or {}
            for _, config in ipairs(provided) do
                configs[#configs + 1] = config
            end
        end
        vim.schedule(function()
            callback(configs)
        end)
    end)
end

local function pick_and_edit_config(dap)
    local ft = vim.bo.filetype
    local bufnr = vim.api.nvim_get_current_buf()
    collect_configs(dap, bufnr, function(configs)
        if #configs == 0 then
            vim.notify(("No DAP configurations for filetype '%s'"):format(ft), vim.log.levels.WARN)
            return
        end

        vim.ui.select(configs, {
            prompt = "Select debug config",
            format_item = function(item)
                return item.name or "(unnamed)"
            end,
        }, function(selected)
            if not selected then
                return
            end

            local config = vim.deepcopy(selected)
            local initial = config_command(config)
            vim.ui.input({ prompt = "Edit command: ", default = initial }, function(cmd)
                if not cmd or vim.trim(cmd) == "" then
                    return
                end

                local words = split_shell_words(vim.trim(cmd))
                if #words == 0 then
                    return
                end

                config.program = words[1]
                config.args = #words > 1 and vim.list_slice(words, 2) or {}
                dap.run(config)
            end)
        end)
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

    keymap("n", "<F5>", dap.continue, { desc = "Start/Continue" })
    keymap("n", "<F11>", dap.step_into, { desc = "Step into" })
    keymap("n", "<F10>", dap.step_over, { desc = "Step over" })
    keymap("n", "<F9>", dap.toggle_breakpoint, { desc = "Toggle breakpoint" })
    keymap("n", "<S-F11>", dap.step_out, { desc = "Step out" })
    keymap("n", "<F23>", dap.step_out, { desc = "Step out (Shift-F11 in terminal)" })

    keymap("n", "<Leader>dc", dap.continue, { desc = "Start/Continue<F5>" })
    keymap("n", "<Leader>dE", function()
        pick_and_edit_config(dap)
    end, { desc = "Select config and edit command" })
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
        "leoluz/nvim-dap-go",
        "mfussenegger/nvim-dap-python",
        "mxsdev/nvim-dap-vscode-js",
    },
    config = function()
        local dap = require("dap")
        local dapview = require("dap-view")

        dapview.setup()
        require("dap-go").setup()

        local js_enabled = setup_js_adapter()
        local has_codelldb = setup_codelldb(dap)

        setup_cpp_configs(dap, has_codelldb)
        setup_python_configs(dap)
        if js_enabled then
            setup_js_configs(dap)
        end

        setup_ui_listeners(dap, dapview)
        setup_keymaps(dap)
        keymap("n", "<Leader>dx", function()
            dap.terminate()
            dapview.close()
        end, { desc = "Exit debugger" })
    end,
}
