local original_prompt = vim.api.nvim_get_hl(0, { name = "SnacksPickerPrompt" })

local picker_highlights = {
    normal = {
        SnacksPickerPrompt = {
            fg = original_prompt.fg,
            bold = true,
            force = true,
        },
    },
    insert = {
        SnacksPickerPrompt = {
            fg = "#aa5533",
            bold = true,
            force = true,
        },
    },
}

vim.api.nvim_create_autocmd("ModeChanged", {
    callback = function()
        if vim.bo.filetype ~= "snacks_picker_input" then
            return
        end

        local mode = vim.fn.mode()
        local hl = ((mode == "i") and picker_highlights.insert) or picker_highlights.normal

        for group, opts in pairs(hl) do
            vim.api.nvim_set_hl(0, group, opts)
        end
    end,
})

vim.api.nvim_create_autocmd("ColorScheme", {
    pattern = "*",
    callback = function()
        -- This is to change the color of the indent scope
        vim.api.nvim_set_hl(0, "SnacksIndentScope", { fg = "#666666" })

        -- This is to change the boldness of mode text
        local modes = {
            "lualine_a_insert",
            "lualine_a_replace",
            "lualine_a_command",
            "lualine_a_terminal",
            "lualine_a_visual",
            "lualine_a_normal",
            "lualine_a_inactive",
        }

        for _, mode in pairs(modes) do
            local mode_hl = vim.api.nvim_get_hl(0, { name = mode, link = false })
            mode_hl.bold = true
            vim.api.nvim_set_hl(0, mode, mode_hl)
        end
    end,
})
