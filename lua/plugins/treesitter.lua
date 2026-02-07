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
    "scss",
    "svelte",
    "typst",
    "vue",
}
return {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    lazy = false,
    branch = "main",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
        local treesitter = require("nvim-treesitter")
        treesitter.install(langs)
    end,
}
