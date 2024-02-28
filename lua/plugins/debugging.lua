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
		local opts = {}
		vim.keymap.set("n", "<Leader>db", dap.toggle_breakpoint, opts)
		vim.keymap.set("n", "<Leader>dc", dap.continue, opts)
	end,
}
