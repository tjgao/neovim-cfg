return {
    -- dir = "/home/tiejun/code/github/quickbuf.nvim",
    -- name = "quickbuf",
    "tjgao/quickbuf.nvim",
    config = function()
        require("quickbuf").setup({
            max_items = 20, -- height cap (line count)
            window = {
                min_width = 0.3,
                max_width = 0.7,
                border = "rounded",
                padding = 2,
            },
        })
    end,
    vim.keymap.set("n", "<Tab>", ":QuickBuf<CR>", { desc = "QuickBuf" }),
    vim.keymap.set("n", "<leader>qt", ":QuickBufPinToggle<CR>", { desc = "QuickBufPinToggle" }),
    vim.keymap.set("n", "<S-h>", ":QuickBufPrevPinned<CR>", { desc = "Prev pinned buffer" }),
    vim.keymap.set("n", "<S-l>", ":QuickBufNextPinned<CR>", { desc = "Next pinned buffer" }),
}
