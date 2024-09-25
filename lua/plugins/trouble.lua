return {
    "folke/trouble.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
        -- your configuration comes here
        -- or leave it empty to use the default settings
        -- refer to the configuration section below
    },
    config = function()
        require("trouble").setup()
        vim.api.nvim_create_user_command("Tt", function()
            vim.g.last_trouble_mode = "telescope"
            vim.cmd("Trouble telescope toggle focus=true")
        end, { desc = "Toggle trouble telescope" })
        vim.api.nvim_create_user_command("Ttf", function()
            vim.g.last_trouble_mode = "telescope_files"
            vim.cmd("Trouble telescope_files toggle focus=true")
        end, { desc = "Toggle trouble telescope files" })
        vim.api.nvim_create_user_command("Tq", function()
            vim.g.last_trouble_mode = "qflist"
            vim.cmd("Trouble qflist toggle focus=true")
        end, { desc = "Toggle trouble qflist" })
        vim.api.nvim_create_user_command("Tl", function()
            vim.g.last_trouble_mode = "loclist"
            vim.cmd("Trouble loclist toggle focus=true")
        end, { desc = "Toggle trouble loclist" })
        vim.api.nvim_create_user_command("Td", function()
            vim.g.last_trouble_mode = "diagnostics"
            vim.cmd("Trouble diagnostics toggle focus=true")
        end, { desc = "Toggle trouble diagnostics" })

        vim.keymap.set({ "n", "v" }, "<C-q>", function()
            local last_trouble_mode = vim.g.last_trouble_mode or "telescope"
            vim.cmd("Trouble " .. last_trouble_mode .. " toggle focus=true")
        end, { silent = true })
    end,
}
