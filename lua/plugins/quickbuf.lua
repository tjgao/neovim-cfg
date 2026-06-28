return {
    dir = "~/code/github/quickbuf.nvim",
    name = "quickbuf",
    -- "tjgao/quickbuf.nvim",
    config = function()
        require("quickbuf").setup({
            persistence = {
                enabled = true,
            },
        })
    end,
}
