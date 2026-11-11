return {
    "zbirenbaum/copilot.lua",
    dependencies = {
        "copilotlsp-nvim/copilot-lsp", -- (optional) for NES functionality
    },
    cmd = "Copilot",
    event = "InsertEnter",
    config = function()
        require("copilot").setup({
            panel = {
                enabled = false, -- Disables the split-window panel so it behaves like Codeium
            },
            suggestion = {
                enabled = true,
                auto_trigger = false, -- Set to false if you want to trigger manually to save your 2,000/mo quota
                debounce = 75,
                keymap = {
                    accept = "<C-y>",
                    accept_word = false,
                    accept_line = false,
                    next = "<C-;>",
                    prev = "<C-,>",
                    dismiss = "<C-x>",
                },
            },
            -- Default deny, then allow only code filetypes you care about.
            filetypes = {
                ["*"] = false,
                ["."] = false,

                -- lua = true,
                python = true,
                -- javascript = true,
                -- typescript = true,
                -- javascriptreact = true,
                -- typescriptreact = true,
                go = true,
                rust = true,
                c = true,
                cpp = true,
                sh = true,
                zsh = true,

                markdown = false,
                help = false,
                gitcommit = false,
                text = false,
                yaml = false,
                toml = false,
                json = false,
            },
        })
    end,
}
