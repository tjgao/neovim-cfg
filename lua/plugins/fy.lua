return {
    dir = "~/code/github/fy.nvim",
    name = "fy",
    -- "tjgao/fy.nvim",
    config = function()
        require("fy").setup({
            override_nvim_notify = true,
        })
    end,
}
