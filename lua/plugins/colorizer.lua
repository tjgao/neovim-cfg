return {
    "norcalli/nvim-colorizer.lua",
    config = function()
        require("colorizer").setup({
            "css",
            "lua",
            "javascript",
            "bash",
            "python",
            html = {
                mode = "foreground",
            },
        })
    end,
}
