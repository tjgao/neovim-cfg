return {
    "nvimtools/none-ls.nvim",
    config = function()
        local null_ls = require("null-ls")
        null_ls.setup({
            sources = {
                null_ls.builtins.formatting.stylua.with {
                    condition = function(utils)
                        return utils.root_has_file { "stylua.toml", ".stylua.toml" }
                    end
                },
                null_ls.builtins.formatting.clang_format.width {
                    condition = function(utils)
                        return utils.root_has_file { ".clang_format" }
                    end
                },
                null_ls.builtins.formatting.black,
                null_ls.builtins.formatting.gofumpt,
                null_ls.builtins.formatting.goimports,
                null_ls.builtins.formatting.prettier,
            },
        })

        vim.keymap.set("n", "<leader>f", vim.lsp.buf.format, { desc = "Format file [None-ls]" })
    end,
}
