local icons = require("settings.icons")

return {
    {
        "hrsh7th/cmp-nvim-lsp",
        dependencies = {
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-path",
            "hrsh7th/cmp-cmdline",
            "hrsh7th/cmp-nvim-lua",
        },
    },
    {
        "L3MON4D3/LuaSnip",
        dependencies = {
            "saadparwaiz1/cmp_luasnip",
            "rafamadriz/friendly-snippets",
        },
    },
    {
        "hrsh7th/nvim-cmp",
        event = "InsertEnter",
        config = function()
            local c = vim.api.nvim_get_hl(0, { name = "Normal" })
            vim.api.nvim_set_hl(0, "MyCmpMenu", { bg = c.bg })
            local cmp = require("cmp")
            require("luasnip.loaders.from_vscode").lazy_load()
            cmp.setup({
                snippet = {
                    -- REQUIRED - you must specify a snippet engine
                    expand = function(args)
                        -- vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` users.
                        require("luasnip").lsp_expand(args.body) -- For `luasnip` users.
                        -- require('snippy').expand_snippet(args.body) -- For `snippy` users.
                        -- vim.fn["UltiSnips#Anon"](args.body) -- For `ultisnips` users.
                    end,
                },
                formatting = {
                    fields = { "kind", "abbr", "menu" },
                    format = function(entry, vim_item)
                        -- Kind icons
                        vim_item.kind = string.format("%s", icons.kind[vim_item.kind])
                        -- vim_item.kind = string.format('%s %s', kind_icons[vim_item.kind], vim_item.kind) -- This concatonates the icons with the name of the item kind
                        vim_item.menu = ({
                            nvim_lsp = "[LSP]",
                            nvim_lua = "[NvimLua]",
                            luasnip = "[Snip]",
                            -- buffer = "[Buf]",
                            path = "[Path]",
                        })[entry.source.name]
                        return vim_item
                    end,
                },
                window = {
                    completion = cmp.config.window.bordered({
                        winhighlight = "Normal:MyCmpMenu,FloatBorder:MyCmpMenu,CursorLine:PmenuSel,Search:None",
                    }),
                    documentation = cmp.config.window.bordered({
                        winhighlight = "Normal:MyCmpMenu,FloatBorder:MyCmpMenu,CursorLine:PmenuSel,Search:None",
                    }),
                },
                mapping = cmp.mapping.preset.insert({
                    ["<C-b>"] = cmp.mapping.scroll_docs(-4),
                    ["<C-f>"] = cmp.mapping.scroll_docs(4),
                    ["<C-Space>"] = cmp.mapping.complete(),
                    ["<C-c>"] = cmp.mapping.abort(),
                    ["<CR>"] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
                }),
                sources = cmp.config.sources({
                    { name = "nvim_lsp" },
                    { name = "nvim_lua" },
                    -- { name = "luasnip" }, -- For luasnip users.
                    { name = "buffer" },
                    { name = "path" },
                    -- { name = "vsnip" }, -- For vsnip users.
                    -- { name = 'ultisnips' }, -- For ultisnips users.
                    -- { name = 'snippy' }, -- For snippy users.
                }, {
                    { name = "buffer" },
                }),
            })

            -- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
            cmp.setup.cmdline({ "/", "?" }, {
                mapping = cmp.mapping.preset.cmdline(),
                sources = {
                    { name = "buffer" },
                },
            })

            -- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
            cmp.setup.cmdline(":", {
                mapping = cmp.mapping.preset.cmdline({
                    ["<C-a>"] = {
                        c = function()
                            vim.api.nvim_feedkeys(
                                vim.api.nvim_replace_termcodes("<Home>", true, false, true),
                                "n",
                                false
                            )
                        end,
                    },
                    ["<C-e>"] = {
                        c = function()
                            vim.api.nvim_feedkeys(
                                vim.api.nvim_replace_termcodes("<End>", true, false, true),
                                "n",
                                false
                            )
                        end,
                    },
                }),
                sources = cmp.config.sources({
                    { name = "path" },
                }, {
                    { name = "cmdline" },
                }),
                matching = { disallow_symbol_nonprefix_matching = false },
            })
        end,
    },
}
