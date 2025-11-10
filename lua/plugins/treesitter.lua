local langs = {
    "c",
    "bash",
    "cpp",
    "css",
    "dockerfile",
    "go",
    "html",
    "json",
    "javascript",
    "latex",
    "lua",
    "markdown",
    "markdown_inline",
    "python",
    "regex",
    "rust",
    "tsx",
    "typescript",
    "vim",
    "vimdoc",
    "yaml",
    "norg",
    "scss",
    "svelte",
    "typst",
    "vue",
}
return {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
        local treesitter = require("nvim-treesitter.configs")
        treesitter.setup({
            ensure_installed = langs,
            highlight = { enable = true },
            indent = { enable = true },
        })
    end,
}
