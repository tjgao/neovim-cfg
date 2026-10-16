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
            "https://codeberg.org/navahas/sanzo.nvim",
            config = function()
                require("sanzo").setup({
                    on_highlights = function(h, p)
                        local soft_fg = "#c8c8b5"
                        local soft_method = "#a8a895" -- "#c9b79b"

                        p.fg = soft_fg
                        p.var = soft_fg

                        h.Normal.fg = soft_fg
                        h.NormalNC.fg = soft_fg
                        h.NormalFloat.fg = soft_fg
                        h.FloatTitle.fg = soft_fg
                        h.CursorLineNr.fg = soft_fg
                        h.WinBar.fg = soft_fg
                        h.SanzoVariable.fg = soft_fg
                        h.SanzoField.fg = soft_method
                        h["@function.method"] = { fg = soft_method }
                        h["@lsp.type.method"] = { fg = soft_method }
                    end,
                })
            end,
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
            "webhooked/polar.nvim",
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
