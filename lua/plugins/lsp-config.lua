if not table.unpack then
    table.unpack = unpack
end
local servers = {
    lua_ls = {
        -- cmd = {...},
        -- filetypes { ...},
        -- capabilities = {},
        settings = {
            Lua = {
                runtime = { version = "LuaJIT" },
                workspace = {
                    checkThirdParty = false,
                    -- Tells lua_ls where to find all the Lua files that you have loaded
                    -- for your neovim configuration.
                    library = {
                        "${3rd}/luv/library",
                        table.unpack(vim.api.nvim_get_runtime_file("", true)),
                    },
                    -- If lua_ls is really slow on your computer, you can try this instead:
                    -- library = { vim.env.VIMRUNTIME },
                },
                completion = {
                    callSnippet = "Replace",
                },
                -- You can toggle below to ignore Lua_LS's noisy `missing-fields` warnings
                -- diagnostics = { disable = { 'missing-fields' } },
            },
        },
    },
    rust_analyzer = {},
    pyright = {},
    gopls = {},
    clangd = {},
    tsserver = {},
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
            mason.setup({
                ui = {
                    border = "single",
                },
            })
        end,
    },
    {
        "WhoIsSethDaniel/mason-tool-installer.nvim",
        config = function()
            require("mason-tool-installer").setup({
                ensure_installed = servers,
            })
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
                handlers = {
                    function(server_name)
                        local capabilities = vim.lsp.protocol.make_client_capabilities()
                        local server = servers[server_name] or {}
                        -- This handles overriding only values explicitly passed
                        -- by the server configuration above. Useful when disabling
                        -- certain features of an LSP (for example, turning off formatting for tsserver)
                        server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
                        require("lspconfig")[server_name].setup(server)
                    end,
                },
            })
        end,
    },
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            { "WhoIsSethDaniel/mason-tool-installer.nvim" },
        },
        config = function()
            local builtin = require("telescope.builtin")
            keymap("n", "K", vim.lsp.buf.hover, {})
            keymap("n", "gd", builtin.lsp_definitions, { desc = "Go to definition" })
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
            keymap("n", "]d", vim.diagnostic.goto_next, { desc = "Go to next diagnostic" })
        end,
    },
}
