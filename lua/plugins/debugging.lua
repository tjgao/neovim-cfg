local function keymap(mode, keys, f, opts)
    if opts.desc ~= nil and opts.desc ~= "" then
        opts.desc = opts.desc .. " [DAP]"
    end
    vim.keymap.set(mode, keys, f, opts)
end

return {
    "mfussenegger/nvim-dap",
    dependencies = {
        "rcarriga/nvim-dap-ui",
        "leoluz/nvim-dap-go",
        -- unpack(daps_install),
    },
    config = function()
        local dap = require("dap")
        local dapui = require("dapui")
        local bp = function()
            dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
        end
        dapui.setup()
        require("dap-go").setup()
        dap.listeners.before.attach.dapui_config = function()
            dapui.open()
        end
        dap.listeners.before.launch.dapui_config = function()
            dapui.open()
        end
        dap.listeners.before.event_terminated.dapui_config = function()
            dapui.close()
        end
        dap.listeners.before.event_exited.dapui_config = function()
            dapui.close()
        end
        keymap("n", "<Leader>db", dap.toggle_breakpoint, { desc = "Toggle breakpoint<F6>" })
        keymap("n", "<Leader>dB", bp, { desc = "Set breakpoint<F7>" })

        keymap("n", "<F6>", dap.toggle_breakpoint, { desc = "Toggle breakpoint" })
        keymap("n", "<F7>", bp, { desc = "Set breakpoint" })
        keymap("n", "<F5>", dap.continue, { desc = "Continue" })
        keymap("n", "<F2>", dap.step_into, { desc = "Step into" })
        keymap("n", "<F3>", dap.step_over, { desc = "Step over" })
        keymap("n", "<F4>", dap.step_out, { desc = "Step out" })
        keymap("n", "<Leader>dc", dap.continue, { desc = "Continue<F5>" })
        keymap("n", "<Leader>di", dap.step_into, { desc = "Step into<F2>" })
        keymap("n", "<Leader>do", dap.step_out, { desc = "Step out<F3>" })
        keymap("n", "<Leader>dv", dap.step_over, { desc = "Step over<F4>" })
    end,
}
