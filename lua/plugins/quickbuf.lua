return {
    -- dir = "/home/tiejun/code/github/quickbuf.nvim",
    -- name = "quickbuf",
    "tjgao/quickbuf.nvim",
    config = function()
        require("quickbuf").setup({
            window = {
                min_width = 0.3,
                max_width = 0.7,
                border = "rounded",
                padding = 2,
            },
        })
    end,
}
