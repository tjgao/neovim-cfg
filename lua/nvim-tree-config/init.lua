if not vim.opt.termguicolors then
    vim.g.nvim_tree_show_icons = {
        git = 0,
        folders = 0,
        files = 0,
        folder_arrrows = 0,
    }
end

require 'nvim-tree'.setup()
