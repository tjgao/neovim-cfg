return {
    "nvim-tree/nvim-tree.lua",
    dependencies = {
        "nvim-tree/nvim-web-devicons", -- optional, for file icon
    },
    config = function()
        if not vim.opt.termguicolors then
            vim.g.nvim_tree_show_icons = {
                git = 0,
                folders = 0,
                files = 0,
                folder_arrrows = 0,
            }
        end
        require("nvim-tree").setup({
            -- this will force nvim tree to find and highlight the file 
            -- currently is open
            update_focused_file = {
                enable = true,
            },
            filters = {
                dotfiles = true,
            },
        })
    end,
}
