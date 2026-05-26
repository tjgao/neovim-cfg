local M = {}

function M.toggle_dap_term()
    local term = require("dap-view.console.view")
    local state = require("dap-view.state")
    local util = require("dap-view.util")

    if util.is_win_valid(state.term_winnr) then
        term.hide_term_buf_win()
    else
        term.open_term_buf_win()
    end
end

function M.setup_ui_listeners(dap, dapview, opts)
    opts = opts or {}

    dap.listeners.after.event_initialized.dap_prelaunch_status = function()
        local task_names = opts.get_active_prelaunch_tasks and opts.get_active_prelaunch_tasks() or {}
        if type(task_names) == "table" and #task_names > 0 then
            vim.notify("preLaunchTask finished, debugger started", vim.log.levels.INFO)
        end
    end
    dap.listeners.after.event_stopped.dapui_config = function()
        dapview.open()
    end
    dap.listeners.before.event_terminated.dapui_config = function()
        if opts.stop_active_prelaunch_task then
            opts.stop_active_prelaunch_task()
        end
        dapview.close()
    end
    dap.listeners.before.event_exited.dapui_config = function()
        if opts.stop_active_prelaunch_task then
            opts.stop_active_prelaunch_task()
        end
        dapview.close()
    end
    dap.listeners.before.disconnect.dap_prelaunch_cleanup = function()
        if opts.stop_active_prelaunch_task then
            opts.stop_active_prelaunch_task()
        end
    end
end

function M.setup_dap_term_buffer_keymap()
    vim.api.nvim_create_autocmd("FileType", {
        pattern = "dap-view-term",
        callback = function(args)
            vim.keymap.set("n", "q", M.toggle_dap_term, {
                buffer = args.buf,
                silent = true,
                desc = "Toggle DAP terminal",
            })
        end,
    })
end

return M
