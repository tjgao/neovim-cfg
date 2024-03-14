return {
    "rafi/awesome-vim-colorschemes",
    dependencies = {
        {
            "catppuccin/nvim",
            name = "catppuccin",
            priority = 1000,
        },
        {
            "EdenEast/nightfox.nvim",
        },
        {
            "tjgao/nord.nvim",
            config = function()
                vim.g.nord_italic = false
                vim.g.nord_treesitter_bold = false
            end,
        },
    },
}
