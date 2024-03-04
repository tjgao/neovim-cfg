local servers = {
    "lua_ls",
    "rust_analyzer",
    "pyright",
    "gopls",
    "clangd",
    "tsserver",
}


local function keymap(mode, keys, f, opts)
    if opts.desc ~= nil and opts.desc ~= "" then
        opts.desc = opts.desc .. " [LSP]"
    end
    vim.keymap.set(mode, keys, f, opts)
end

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
            local builtin = require("telescope.builtin")
            local capabilities = require("cmp_nvim_lsp").default_capabilities()
            local cfg = require("lspconfig")
            for _, v in ipairs(servers) do
                cfg[v].setup({
                    capabilities = capabilities,
                })
            end
            local opts = {}
            keymap("n", "K", vim.lsp.buf.hover, opts)
            keymap("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })
            keymap("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code action" })

            keymap("n", "gD", vim.lsp.buf.declaration, { desc = "Go to declaration" })
            keymap("n", "gi", vim.lsp.buf.implementation, { desc = "Go to implementation" })
            keymap("n", "KK", vim.lsp.buf.signature_help, { desc = "Signature help" })
            keymap("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename func/var" })
            -- keymap("n", "gr", ":Trouble lsp_references<CR>", { desc = "Find references" })
            keymap("n", "gr", builtin.lsp_references, { desc = "Find references" })
            keymap("n", "<leader>gd", ":Trouble workspace_diagnostics<CR>", { desc = "Show diagnostics" })
            -- vim.keymap.set("n", "gl", vim.diagnostic.open_float, opts)
            -- vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, opts)
            keymap("n", "[d", vim.diagnostic.goto_prev, { desc = "Go to prev diagnostic" })
            keymap("n", "]d", vim.diagnostic.goto_next, { desc = "Go to next diagnostic"})
        end,
    },
}
