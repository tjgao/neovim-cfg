local servers = {
    lua_ls = {
        -- cmd = {...},
        -- filetypes { ...},
        -- capabilities = {},
        settings = {
            Lua = {
                runtime = { version = "LuaJIT" },
                workspace = {
                    library = {
                        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
                        { path = "lazy.nvim", words = { "LazyVim" } },
                        table.unpack(vim.api.nvim_get_runtime_file("", true)),
                    },
                },
                completion = {
                    callSnippet = "Replace",
                },
                -- You can toggle below to ignore Lua_LS's noisy `missing-fields` warnings
                -- diagnostics = { disable = { "missing-fields" } },
                diagnostics = {
                    disable = { "missing-fields" },
                },
            },
        },
    },
    rust_analyzer = {},
    pyright = {},
    gopls = {},
    clangd = {},
    ts_ls = {},
}

local keymap = require("shared.utils").keymap

return {
    {
        "mason-org/mason.nvim",
        -- branch = "main",
        config = function()
            local mason = require("mason")
            mason.setup({
                ui = {
                    border = "single",
                },
            })
        end,
    },
    {
        "mason-org/mason-lspconfig.nvim",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "mason-org/mason.nvim",
        },
        config = function()
            local masonlsp = require("mason-lspconfig")
            for server_name, server in pairs(servers) do
                vim.lsp.config(server_name, server)
            end
            masonlsp.setup()
        end,
    },
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            { "WhoIsSethDaniel/mason-tool-installer.nvim" },
        },
        opts = { inlay_hints = { enabled = true } },
        config = function()
            vim.api.nvim_create_autocmd("CursorHold", {
                desc = "Show errors/warnings when cursor stopped for some time",
                group = vim.api.nvim_create_augroup("CursorHoldGroup", { clear = true }),
                callback = function()
                    if vim.diagnostic.is_enabled() then
                        vim.diagnostic.open_float({ focusable = false })
                    end
                end,
            })
            local Snacks = require("snacks")
            keymap("n", "K", vim.lsp.buf.hover, { desc = "Hover help" })
            keymap("n", "gd", function()
                Snacks.picker.pick({
                    source = "lsp_definitions",
                    formatters = {
                        file = {
                            filename_first = true,
                            min_width = 100,
                        },
                    },
                    focus = "list",
                })
            end, { desc = "Go to definition" })
            keymap("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code action" })
            keymap("n", "gi", vim.lsp.buf.implementation, { desc = "Go to implementation" })
            keymap("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename func/var" })
            keymap("n", "gr", function()
                Snacks.picker.pick({
                    source = "lsp_references",
                    formatters = {
                        file = {
                            filename_first = true,
                            min_width = 100,
                        },
                    },
                    focus = "list",
                })
            end, { desc = "Find LSP references" })
            keymap("n", "[d", function()
                vim.diagnostic.jump({ count = -1 })
            end, { desc = "Go to prev diagnostic" })
            keymap("n", "]d", function()
                vim.diagnostic.jump({ count = 1 })
            end, { desc = "Go to next diagnostic" })
        end,
    },
}
