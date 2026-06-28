return {
    dir = "/home/tiejun/code/github/fy.nvim",
    name = "fy",
    config = function()
        require("fy").setup({
            override_nvim_notify = true,
        })
    end,
}
