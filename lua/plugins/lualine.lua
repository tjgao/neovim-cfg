return {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons", opt = true },
    config = function()
        local lualine = require("lualine")
        local config = {
            options = {
                icons_enabled = vim.opt.termguicolors,
                theme = "nord",
                --    	component_separators = '',
                --    	section_separators = '',
            },
        }
        lualine.setup(config)
    end,
}
