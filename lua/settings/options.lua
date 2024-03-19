local options = {
    backup = false,                               -- creates backup file
    spelllang = "en_au",                          -- spell checking language
    swapfile = false,                             -- creates swap file
    clipboard = "unnamedplus",                    -- allows neovim to access the system clipboard
    ignorecase = true,                            -- ignores case in search
    smartcase = true,                             -- smart case, search pattern in lower case will ignore case, otherwise not
    fileencoding = "utf-8",                       -- the encoding used in writing files
    --    cmdheight = 2,                                -- more space in command line for displaying messages
    completeopt = { "menuone", "noselect" },      -- for cmp
    termguicolors = true,                         -- for most terminals this is supported
    --    mouse = 'a',                                  -- allows mouse use
    tabstop = 4,                                  -- inserts 4 spaces for a tab
    shiftwidth = 4,                               -- the number of spaces inserted for each indentation
    softtabstop = 4,                              -- how many columns (spaces) cursor moves right for a tab press, and left for a BS
    wrap = false,                                 -- do not wrap long lines
    expandtab = true,                             -- converts tabs to spaces
    number = true,                                -- shows line numbers
    --    relativenumber = true,                        -- shows relative line numbers for quick jump
    scrolloff = 8,                                -- always leaves some space above/below if possible
    sidescrolloff = 8,                            -- always leaves some space left/right if possible
    numberwidth = 4,                              -- the width for line number
    signcolumn = "yes",                           -- allows to show sign column
    splitbelow = true,                            -- force horizontal splits to go below
    splitright = true,                            -- force vertical spllits to go right
    wildmode = "longest:full",                    -- do not want auto select for wildmenu
    guifont = "UbuntuMono Nerd Font Regular:h16", -- font used in GUI neovim app
}

vim.opt.shortmess:append("c")

for k, v in pairs(options) do
    vim.opt[k] = v
end

vim.g.tmux_navigator_disable_when_zoomed = 1 -- disable tmux nav when zoomed
vim.g.mapleader = " "
vim.g.maplocalleader = " "
