-- local autoformat_filetypes = { go = {}, lua = {}, json = {}, python = {}, javascript = {} }
-- local group = vim.api.nvim_create_augroup("AutoFormatGroup", {})
-- vim.api.nvim_create_autocmd({ "BufWritePre" }, {
--     desc = "Call None-ls formatting automatically",
--     group = group,
--     callback = function(opts)
-- if autoformat_filetypes[vim.bo[opts.buf].filetype] ~= nil then
--             vim.lsp.buf.format({ async = false })
-- end
--     end,
-- })

local autofmt_patterns = { "*.go", "*.lua", "*.json", "*.py", "*.js", "*.ts", "*.tsx", "*.jsx", "*.html" }
local group_name = "AutoFormatGroup_None-ls"
local install_autofmt = function(patterns)
    local group = vim.api.nvim_create_augroup(group_name, {})
    vim.api.nvim_create_autocmd({ "BufWritePre" }, {
        desc = "Call None-ls formatting automatically",
        group = group,
        pattern = patterns,
        callback = function()
            vim.lsp.buf.format({ async = false })
        end,
    })
end

local remove_autofmt = function()
    vim.api.nvim_del_augroup_by_name(group_name)
end

local toggle_autofmt = function(show_notification)
    local notify = require("notify")
    local group = vim.api.nvim_create_augroup(group_name, { clear = false })
    local cmds = vim.api.nvim_get_autocmds({
        group = group,
        event = { "BufWritePre" },
    })

    if #cmds == 0 then
        if show_notification then
            notify("AutoFormat is turned on for " .. table.concat(autofmt_patterns, ", "))
        end
        install_autofmt(autofmt_patterns)
    else
        if show_notification then
            notify("AutoFormat is turned off")
        end
        remove_autofmt()
    end
end

return {
    "nvimtools/none-ls.nvim",
    dependencies = { "rcarriga/nvim-notify" },
    config = function()
        local null_ls = require("null-ls")
        null_ls.setup({
            sources = {
                null_ls.builtins.formatting.stylua.with({
                    extra_args = { "--indent-type", "Spaces" },
                    -- condition = function(utils)
                    --     return utils.root_has_file({ "stylua.toml", ".stylua.toml" })
                    -- end,
                }),
                null_ls.builtins.formatting.clang_format.with({
                    condition = function(utils)
                        return utils.root_has_file({ ".clang_format" })
                    end,
                }),
                null_ls.builtins.formatting.black,
                null_ls.builtins.formatting.gofumpt,
                null_ls.builtins.formatting.goimports,
                null_ls.builtins.formatting.prettier.with({
                    extra_args = function(params)
                        return params.options
                            and params.options.tabSize
                            and {
                                "--tab-width",
                                params.options.tabSize,
                            }
                    end,
                }),
            },
        })
        toggle_autofmt()
        vim.keymap.set("n", "<leader>af", function()
            toggle_autofmt(true)
        end, { desc = "Toggle auto format" })
        vim.keymap.set("n", "<leader>f", vim.lsp.buf.format, { desc = "Format file [None-ls]" })
    end,
}
