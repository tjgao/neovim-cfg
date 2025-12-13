local keymap = require("shared.utils").keymap

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
keymap("n", "<A-S-p>", '"0P', "Past last yanked using P")

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
keymap("n", "<C-m>", ":noh<CR>", "Clear search highlight")

keymap("n", "<leader>rh", ":Gitsigns reset_hunk<CR>", "Reset hunk [Gitsigns]")

-- Diffview handy keymaps --
-- keymap("n", "<leader>dd", ":DiffviewClose<CR>", "Close [Diffview]")
-- for some reason DiffviewClose sometimes doesn't work, have to close tab directly
keymap("n", "<leader>dd", ":tabclose<CR>", "Close [Diffview]")
keymap("n", "<leader>df", ":DiffviewFileHistory %<CR>", "File history [Diffview]")

-- Small things --
keymap("n", "<C-0>", "^", "Go to beginning of line")
keymap("n", "<leader>an", ":set relativenumber!<CR>", "Toggle relativenumber")
keymap("n", "<leader>ad", ":lua vim.diagnostic.enable(not vim.diagnostic.is_enabled())<CR>", "Toggle diagnostics")

keymap("n", "]h", ":Gitsigns next_hunk<CR>", { desc = "Gitsigns: Go to next hunk" })
keymap("n", "[h", ":Gitsigns prev_hunk<CR>", { desc = "Gitsigns: Go to previous hunk" })

keymap("n", "<C-f>", "<C-f>zz", "Scroll down")
keymap("n", "<C-b>", "<C-b>zz", "Scroll up")
keymap("n", "n", "nzzzv", "Next search result")
keymap("n", "N", "Nzzzv", "Previous search result")

keymap("n", "<C-,>", ":LspClangdSwitchSourceHeader<CR>", "Switch source and header")

-- Obsidian --
keymap("n", "<leader>on", ":ObsidianNew<CR>", "Open new note [Obsidian]")
keymap("n", "<leader>os", ":ObsidianSearch<CR>", "Search note [Obsidian]")

keymap("n", "<leader>tt", ":TSJToggle<CR>", "Toggle treesitter join")

keymap("n", "<leader>qq", function()
    require("quicker").toggle()
end, "Toggle quickfix")

keymap("n", "<leader>ql", function()
    require("quicker").toggle({ loclist = true })
end, "Toggle loclist")

keymap("n", "<leader>sn", function()
    require("snacks").notifier.show_history()
end, "Show notifier history")

keymap("n", "<Tab>", ":b#<CR>zz", "Jump to the most recent buffer")
