local keymap = require("shared.utils").keymap

local M = {}

function M.setup(dap, handlers)
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
        handlers.continue_or_run_single_or_pick(dap)
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
        handlers.open_config_picker(dap)
    end, { desc = "Continue or pick config" })
    keymap("n", "<Leader>dl", function()
        handlers.open_breakpoint_picker(dap)
    end, { desc = "List breakpoints" })
    keymap("n", "<Leader>dt", handlers.toggle_dap_term, { desc = "Toggle DAP terminal" })
    keymap("n", "<Leader>di", dap.step_into, { desc = "Step into<F11>" })
    keymap("n", "<Leader>do", dap.step_out, { desc = "Step out<S-F11>" })
    keymap("n", "<Leader>dv", dap.step_over, { desc = "Step over<F10>" })
end

return M
