local keymap = require("shared.utils").keymap

return {
    "mfussenegger/nvim-dap",
    dependencies = {
        {
            "igorlfs/nvim-dap-view",
            -- let the plugin lazy load itself
            version = "1.*",
            opts = {},
        },
        "leoluz/nvim-dap-go",
    },
    config = function()
        local dap = require("dap")
        local dapview = require("dap-view")
        dapview.setup()
        require("dap-go").setup()

        local break_cond = function()
            dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
        end
        local break_hit = function()
            dap.set_breakpoint(nil, vim.fn.input("Hit condition (e.g. 10 or > 10): "))
        end

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
        keymap("n", "<Leader>di", dap.step_into, { desc = "Step into<F11>" })
        keymap("n", "<Leader>do", dap.step_out, { desc = "Step out<S-F11>" })
        keymap("n", "<Leader>dv", dap.step_over, { desc = "Step over<F10>" })
        keymap("n", "<Leader>dx", function()
            dap.terminate()
            dapview.close()
        end, { desc = "Exit debugger" })
    end,
}
