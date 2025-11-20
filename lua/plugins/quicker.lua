return {
    "stevearc/quicker.nvim",
    ft = "qf",
    ---@module "quicker"
    ---@type quicker.SetupOptions
    opts = {},
    config = function()
        local Q = require("quicker")
        Q.setup({
            keys = {
                {
                    ">",
                    function()
                        Q.expand({ before = 2, after = 2, add_to_existing = true })
                    end,
                    desc = "Expand quickfix context",
                },
                {
                    "<",
                    function()
                        Q.collapse()
                    end,
                    desc = "Collapse quickfix context",
                },
            },
        })
    end,
}
