local keymap = function(mode, key, action, desc)
    local opts = { noremap = true, silent = true }
    opts.desc = desc
    vim.keymap.set(mode, key, action, opts)
end

--Remap space as leader key
keymap("", "<Space>", "<Nop>", "Leader remap")

-- Modes
--   normal_mode = "n",
--   insert_mode = "i",
--   visual_mode = "v",
--   visual_block_mode = "x",
--   term_mode = "t",
--   command_mode = "c",

-- Normal --
-- Tmux --
keymap("n", "<C-h>", ":TmuxNavigateLeft<CR>", "Move left [Tmux-nav]")
keymap("n", "<C-l>", ":TmuxNavigateRight<CR>", "Move right [Tmux-nav]")
keymap("n", "<C-k>", ":TmuxNavigateUp<CR>", "Move up [Tmux-nav]")
keymap("n", "<C-j>", ":TmuxNavigateDown<CR>", "Move down [Tmux-nav]")

-- Resize with arrows
keymap("n", "<C-Up>", ":resize +2<CR>", "Resize window upward")
keymap("n", "<C-Down>", ":resize -2<CR>", "Resize window downward")
keymap("n", "<C-Left>", ":vertical resize +2<CR>", "Resize window leftward")
keymap("n", "<C-Right>", ":vertical resize -2<CR>", "Resize window rightward")

-- Navigate buffers
keymap("n", "<S-l>", ":bnext<CR>", "Go to next buf")
keymap("n", "<S-h>", ":bprevious<CR>", "Go to previous buf")

-- Retrieve last thing yanked instead of deleted
keymap("n", "<A-p>", '"0p', "Past last yanked instead of deleted")

-- nvim-tree
keymap("n", "<F1>", ":NvimTreeToggle<CR>", "Toggle NvimTree")

-- Insert --
-- Press jk fast to enter
keymap("i", "jk", "<ESC>", "Alternative for ESC in insert mode")

-- Visual --
-- Stay in indent mode
keymap("v", "<", "<gv", "Move visual selected left")
keymap("v", ">", ">gv", "Move visual selected right")
keymap("v", "<S-h>", "<gv", "Move visual selected left")
keymap("v", "<S-l>", ">gv", "Move visual selected right")

-- Visual Block --
-- Move text up and down
keymap("x", "J", ":move '>+1<CR>gv-gv", "Move visual selected down")
keymap("x", "K", ":move '<-2<CR>gv-gv", "Move visual selected up")
keymap("x", "<A-j>", ":move '>+1<CR>gv-gv", "Move visual selected down")
keymap("x", "<A-k>", ":move '<-2<CR>gv-gv", "Move visual selected up")

keymap("n", "mm", ":noh<CR>", "Clear search highlight")

keymap("n", "<leader>rh", ":Gitsigns reset_hunk<CR>", "Reset hunk (drop changes)")
