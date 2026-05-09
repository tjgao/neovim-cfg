return {
    "stevearc/overseer.nvim",
    cmd = {
        "OverseerRun",
        "OverseerToggle",
        "OverseerQuickAction",
        "OverseerTaskAction",
        "OverseerInfo",
    },
    keys = {
        { "<leader>or", "<cmd>OverseerRun<cr>", desc = "Overseer run task" },
        { "<leader>ot", "<cmd>OverseerToggle<cr>", desc = "Overseer toggle list" },
        { "<leader>oa", "<cmd>OverseerTaskAction<cr>", desc = "Overseer task action" },
        { "<leader>oq", "<cmd>OverseerQuickAction<cr>", desc = "Overseer quick action" },
    },
    opts = {
        dap = true,
    },
    config = function(_, opts)
        require("overseer").setup(opts)
    end,
}
