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

    local prelaunch_tasks = debug_state.get_prelaunch_task_names(runnable)
    if #prelaunch_tasks > 0 then
        vim.notify(("Running preLaunchTask(s): %s"):format(table.concat(prelaunch_tasks, ", ")), vim.log.levels.INFO)
    end
    debug_state.set_active_prelaunch_tasks_from_config(runnable)
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
        "stevearc/overseer.nvim",
    },
    config = function()
        local dap = require("dap")
        local dapview = require("dap-view")
        local ok_overseer, overseer = pcall(require, "overseer")

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

        if ok_overseer then
            overseer.enable_dap()
        end

        debug_ui.setup_ui_listeners(dap, dapview, {
            get_active_prelaunch_tasks = debug_state.get_active_prelaunch_tasks,
            stop_active_prelaunch_task = debug_state.stop_active_prelaunch_tasks,
        })
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
