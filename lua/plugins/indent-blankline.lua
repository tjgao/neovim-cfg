return {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    config = function()
        require("ibl").setup({
            indent = {
                char = "",
            },
            scope = {
                -- if set enabled to true, we have scope highlighted indent line
                -- but feel a little bit distracting, disable for now
                enabled = false,
                show_start = false,
                show_end = false,
            },
        })
    end,
}
