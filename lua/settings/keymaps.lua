local keymap = function(mode, key, action, desc)
    local opts = { noremap = true, silent = true }
    opts.desc = desc
    vim.keymap.set(mode, key, action, opts)
end

--Remap space as leader key
keymap("", "<Space>", "<Nop>", "Leader remap")
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Modes
--   normal_mode = "n",
--   insert_mode = "i",
--   visual_mode = "v",
--   visual_block_mode = "x",
--   term_mode = "t",
--   command_mode = "c",

-- Normal --
-- Better window navigation
keymap("n", "<C-h>", "<C-w>h", "Move left to next window")
keymap("n", "<C-j>", "<C-w>j", "Move down to next window")
keymap("n", "<C-k>", "<C-w>k", "Move up to next window")
keymap("n", "<C-l>", "<C-w>l", "Move right to next window")

-- Resize with arrows
keymap("n", "<C-Up>", ":resize +2<CR>", "Resize window upward")
keymap("n", "<C-Down>", ":resize -2<CR>", "Resize window downward")
keymap("n", "<C-Left>", ":vertical resize +2<CR>", "Resize window leftward")
keymap("n", "<C-Right>", ":vertical resize -2<CR>", "Resize window rightward")

-- Navigate buffers
keymap("n", "<S-l>", ":bnext<CR>", "Go to next buf")
keymap("n", "<S-h>", ":bprevious<CR>", "Go to previous buf")

-- Retrieve last thing yanked instead of deleted
keymap("n", "<A-p>", "\"0p", "Past last yanked instead of deleted")

-- Toggle quickfix window
-- keymap("n", "<C-q>", ":lua require('commands').ToggleQF()<CR>", opts)

-- Telescope search file window
-- keymap("n", "<C-p>", ":lua require('telescope-config').file_search()<CR>", opts)

-- Toggle symbols outline window
-- keymap("n", "<A-a>", ":lua require('symbols-outline').toggle_outline()<CR>", opts)

-- nvim-tree
keymap("n", "<F1>", ":NvimTreeToggle<CR>", "Toggle NvimTree")

-- Move text up and down
-- keymap("n", "<A-j>", "<Esc>:m .+1<CR>==gi", opts)
-- keymap("n", "<A-k>", "<Esc>:m .-2<CR>==gi", opts)

-- Insert --
-- Press jk fast to enter
keymap("i", "jk", "<ESC>", "Alternative for ESC in insert mode")

-- Visual --
-- Stay in indent mode
keymap("v", "<", "<gv", "Move visual selected left")
keymap("v", ">", ">gv", "Move visual selected right")
keymap("v", "<S-h>", "<gv", "Move visual selected left")
keymap("v", "<S-l>", ">gv", "Move visual selected right")

-- Move text up and down
-- keymap("v", "<A-j>", ":m .+1<CR>==", opts)
-- keymap("v", "<A-k>", ":m .-2<CR>==", opts)
-- keymap("v", "p", '"_dP', opts)

-- Visual Block --
-- Move text up and down
keymap("x", "J", ":move '>+1<CR>gv-gv", "Move visual selected down")
keymap("x", "K", ":move '<-2<CR>gv-gv", "Move visual selected up")
keymap("x", "<A-j>", ":move '>+1<CR>gv-gv", "Move visual selected down")
keymap("x", "<A-k>", ":move '<-2<CR>gv-gv", "Move visual selected up")

keymap("n", "mm", ":noh<CR>", "Clear search highlight")

-- Terminal --
-- Better terminal navigation
-- keymap("t", "<C-h>", "<C-\\><C-N><C-w>h", term_opts)
-- keymap("t", "<C-j>", "<C-\\><C-N><C-w>j", term_opts)
-- keymap("t", "<C-k>", "<C-\\><C-N><C-w>k", term_opts)
-- keymap("t", "<C-l>", "<C-\\><C-N><C-w>l", term_opts)

