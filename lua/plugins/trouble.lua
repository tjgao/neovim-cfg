return {
    "folke/trouble.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
        -- your configuration comes here
        -- or leave it empty to use the default settings
        -- refer to the configuration section below
    },
    cmd = "Trouble",
    keys = {
        {
            "<leader>td",
            "<cmd>Trouble diagnostics toggle<cr>",
            desc = "Toggle trouble diagnostics",
        },
        {
            "<leader>tq",
            "<cmd>Trouble qflist toggle<cr>",
            desc = "Toggle trouble quickfix list",
        },
        {
            "<leader>tl",
            "<cmd>Trouble loclist toggle<cr>",
            desc = "Toggle trouble location list",
        },
    },
}
