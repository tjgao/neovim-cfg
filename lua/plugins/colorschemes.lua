return {
    "EdenEast/nightfox.nvim",
    dependencies = {
        { "AlexvZyl/nordic.nvim" },
        {
            "catppuccin/nvim",
            name = "catppuccin",
            priority = 1000,
        },
        {
            "vague-theme/vague.nvim",
        },
        {
            "webhooked/kanso.nvim",
        },
        {
            "rafi/awesome-vim-colorschemes",
        },
        {
            "sainnhe/everforest",
            config = function()
                vim.g.everforest_background = "hard"
            end,
        },
        {
            "rose-pine/neovim",
            name = "rose-ine",
        },
        {
            "folke/tokyonight.nvim",
            name = "tokyonight",
        },
        {
            "tjgao/nord.nvim",
            branch = "wsl",
            name = "tjnord",
            config = function()
                vim.g.nord_italic = false
                vim.g.nord_treesitter_bold = false
            end,
        },
        {
            "cocopon/iceberg.vim",
        },
        {
            "slugbyte/lackluster.nvim",
        },
    },
}
