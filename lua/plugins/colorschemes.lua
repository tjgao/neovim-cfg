return {
    "EdenEast/nightfox.nvim",
    dependencies = {
        { "AlexvZyl/nordic.nvim" },
        {
            "catppuccin/nvim",
            name = "catppuccin",
            priority = 1000,
        },
        -- {
        --     "rafi/awesome-vim-colorschemes",
        -- },
        {
            "tjgao/nord.nvim",
            config = function()
                vim.g.nord_italic = false
                vim.g.nord_treesitter_bold = false
            end,
        },
    },
}
