return {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
        local lspconfig = require("nvim-treesitter.configs")
        lspconfig.setup({
            ensure_installed = { "markdown", "html", "javascript", "bash", "python", "cpp", "go", "lua" },
            hightlight = { enable = true },
            indent = { enable = true },
        })
    end,
}
