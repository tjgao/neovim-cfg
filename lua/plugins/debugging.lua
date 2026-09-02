local keymap = require("shared.utils").keymap
local debug_adapters = require("users.debug.adapters")
local debug_breakpoints = require("users.debug.breakpoints")
local debug_config_picker = require("users.debug.config_picker")
local debug_keymaps = require("users.debug.keymaps")
local debug_state = require("users.debug.state")
local debug_ui = require("users.debug.ui")

local function initialize_debug_backends(dap)
    if debug_state.is_initialized() then
        return
    end

    debug_state.set_js_enabled(debug_adapters.setup_js_adapter())
    debug_adapters.setup_gdb_adapter(dap)
    debug_adapters.setup_nlua_adapter(dap)

    debug_state.set_initialized(true)
end

local function run_selected_config(dap, config, opts)
    opts = opts or {}
    initialize_debug_backends(dap)

    local runnable, err = debug_adapters.prepare_config_for_run(dap, config)
    if not runnable then
        vim.notify(err or "Debug config cannot run", vim.log.levels.ERROR)
        return
    end

    if opts.remember ~= false then
        debug_config_picker.remember_last_launch_config(runnable)
    end

    dap.run(runnable)
end

local function open_config_picker(dap)
    debug_config_picker.open_picker(dap, {
        initialize_debug_backends = initialize_debug_backends,
        run_selected_config = run_selected_config,
    })
end

local function continue_or_run_single_or_pick(dap)
    debug_config_picker.continue_or_run_single_or_pick(dap, {
        initialize_debug_backends = initialize_debug_backends,
        run_selected_config = run_selected_config,
    })
end

local function open_breakpoint_picker(dap)
    debug_breakpoints.open_picker(dap)
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
        "jbyuki/one-small-step-for-vimkind",
        { dir = "/home/tiejun/code/github/fy.nvim", name = "fy.nvim" },
        { dir = "/home/tiejun/code/github/flyout.nvim", name = "flyout.nvim" },
    },
    config = function()
        local dap = require("dap")
        local dapview = require("dap-view")
        local flyout = require("flyout")

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

        dapview.setup({
            auto_toggle = "open_term",
            windows = {
                terminal = {
                    position = "right",
                },
            },
        })
        require("dap-go").setup()

        local _, flyout_err = flyout.enable_dap()
        if flyout_err then
            vim.notify("Flyout: " .. tostring(flyout_err), vim.log.levels.ERROR)
        end

        debug_ui.setup_ui_listeners(dap, dapview)
        debug_config_picker.setup_cache_invalidation()
        debug_keymaps.setup(dap, {
            continue_or_run_single_or_pick = continue_or_run_single_or_pick,
            open_config_picker = open_config_picker,
            open_breakpoint_picker = open_breakpoint_picker,
            toggle_dap_term = debug_ui.toggle_dap_term,
        })
        debug_ui.setup_dap_term_buffer_keymap()
        keymap("n", "<Leader>dx", function()
            dap.terminate()
            dapview.close()
        end, { desc = "Exit debugger" })
    end,
}
