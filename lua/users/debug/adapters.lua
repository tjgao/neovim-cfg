local M = {}

function M.find_executable(candidates)
    for _, candidate in ipairs(candidates) do
        if vim.fn.executable(candidate) == 1 then
            return candidate
        end
    end
    return nil
end

function M.find_js_debug_adapter()
    local from_path = M.find_executable({ "js-debug-adapter", "js-debug-adapter.cmd" })
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

function M.setup_js_adapter()
    local js_debug_adapter = M.find_js_debug_adapter()
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

function M.setup_gdb_adapter(dap)
    local gdb = M.find_executable({ "gdb" })
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

function M.setup_nlua_adapter(dap)
    dap.adapters.nlua = function(callback, config)
        callback({
            type = "server",
            host = config.host or "127.0.0.1",
            port = config.port or 8086,
        })
    end
    return true
end

function M.adapter_is_configured(dap, adapter_name)
    return dap.adapters and dap.adapters[adapter_name] ~= nil
end

function M.prepare_config_for_run(dap, config)
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
        nlua = "nlua adapter is not available (install one-small-step-for-vimkind)",
    }

    local error_message = adapter_checks[runnable.type]
    if error_message and not M.adapter_is_configured(dap, runnable.type) then
        return nil, error_message
    end

    return runnable
end

return M
