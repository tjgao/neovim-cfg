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
            "qml",
            "html",
            "svelte",
            html = {
                mode = "foreground",
            },
        })
    end,
}
