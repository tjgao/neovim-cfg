return {
    "norcalli/nvim-colorizer.lua",
    config = function()
        require("colorizer").setup({
            "css",
            "lua",
            "javascript",
            html = {
                mode = "foreground",
            },
        })
    end,
}
