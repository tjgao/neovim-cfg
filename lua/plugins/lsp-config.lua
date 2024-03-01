local servers = {
    "lua_ls",
    "rust_analyzer",
    "pyright",
    "gopls",
    "clangd",
    "tsserver",
}

return {
    {
        "williamboman/mason.nvim",
        -- branch = "main",
        config = function()
            local mason = require("mason")
            mason.setup()
        end,
    },
    {
        "williamboman/mason-lspconfig.nvim",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "williamboman/mason.nvim",
        },
        config = function()
            local masonlsp = require("mason-lspconfig")
            masonlsp.setup({
                ensure_installed = servers,
            })
        end,
    },
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            { "folke/neoconf.nvim", cmd = "Neoconf", config = true },
        },
        config = function()
            local capabilities = require("cmp_nvim_lsp").default_capabilities()
            local cfg = require("lspconfig")
            for _, v in ipairs(servers) do
                cfg[v].setup({
                    capabilities = capabilities,
                })
            end
            local opts = {}
            vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
            vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition [LSP]" })
            vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code action [LSP]" })

            vim.keymap.set("n", "gD", vim.lsp.buf.declaration, { desc = "Go to declaration [LSP]" })
            vim.keymap.set("n", "gi", vim.lsp.buf.implementation, { desc = "Go to implementation [LSP]" })
            vim.keymap.set("n", "KK", vim.lsp.buf.signature_help, { desc = "Signature help [LSP]" })
            vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename func/var [LSP]" })
            vim.keymap.set("n", "gr", ":Trouble lsp_references<CR>", { desc = "Find references [LSP]" })
            vim.keymap.set("n", "<leader>gd", ":Trouble workspace_diagnostics<CR>", { desc = "Show diagnostics [LSP]" })
            -- vim.keymap.set("n", "gl", vim.diagnostic.open_float, opts)
            -- vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, opts)
            -- vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
            -- vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
        end,
    },
}
