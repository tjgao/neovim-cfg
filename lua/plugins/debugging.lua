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
        keymap("n", "<Leader>db", dap.toggle_breakpoint, { desc = "Toggle breakpoint" })
        keymap("n", "<Leader>dB", function()
            dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
        end, { desc = "Set breakpoint" })

        keymap("n", "<F5>", dap.continue, { desc = "Continue" })
        keymap("n", "<F2>", dap.step_into, { desc = "Step into" })
        keymap("n", "<F3>", dap.step_over, { desc = "Step over" })
        keymap("n", "<F4>", dap.step_out, { desc = "Step out" })
        keymap("n", "<Leader>dc", dap.continue, { desc = "Continue" })
        keymap("n", "<Leader>di", dap.step_into, { desc = "Step into" })
        keymap("n", "<Leader>do", dap.step_out, { desc = "Step out" })
        keymap("n", "<Leader>dv", dap.step_over, { desc = "Step over" })
    end,
}
