return {
    "norcalli/nvim-colorizer.lua",
    config = function()
        require("colorizer").setup({
            "css",
            "lua",
            "javascript",
            "typescript",
            "go",
            "c",
            "cpp",
            "rust",
            "bash",
            "python",
            html = {
                mode = "foreground",
            },
        })
    end,
}
