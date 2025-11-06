-- This is to change the color of the indent scope
vim.api.nvim_create_autocmd("ColorScheme", {
    pattern = "*",
    callback = function()
        vim.api.nvim_set_hl(0, "SnacksIndentScope", { fg = "#666666" })
    end,
})
