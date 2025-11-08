return {
    "folke/snacks.nvim",
    lazy = false,
    ---@type snacks.Config
    opts = {
        bigfile = { enabled = true },
        explorer = { enabled = false },
        picker = {
            enabled = true,
            layout = {
                backdrop = true,
            },
            matcher = { frecency = true },
            formatters = {
                file = {
                    filename_first = true,
                },
            },
            previewers = {
                diff = {
                    style = "syntax",
                },
            },
            win = {
                input = {
                    keys = {
                        ["<C-j>"] = { "preview_scroll_down", mode = { "i", "n" } },
                        ["<C-k>"] = { "preview_scroll_up", mode = { "i", "n" } },
                        ["<C-h>"] = { "preview_scroll_left", mode = { "i", "n" } },
                        ["<C-l>"] = { "preview_scroll_right", mode = { "i", "n" } },
                    },
                },
            },
        },
        indent = {
            indent = {
                enabled = false,
            },
            chunk = {
                enabled = true,
                char = {
                    horizontal = "─",
                    vertical = "│",
                    corner_top = "╭",
                    corner_bottom = "╰",
                    arrow = "─",
                },
            },
        },
        -- indent = { enabled = true },
        dashboard = {
            enabled = true,
            preset = {
                header = [[

 ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
 ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
 ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
 ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
 ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
 ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝

                ]],
            },
            sections = {
                { section = "header" },
                {
                    section = "keys",
                    indent = 1,
                    padding = 1,
                },
                { section = "recent_files", title = "Recent Files" },
                { section = "startup" },
            },
        },
    },
    keys = {
        {
            "<leader><space>",
            function()
                Snacks.picker()
            end,
            desc = "Snacks Menu",
        },
        {
            "<leader>p",
            function()
                Snacks.picker.git_files({
                    layout = "vertical",
                })
            end,
            desc = "Search git files",
        },
        {
            "<leader>b",
            function()
                Snacks.picker.buffers({
                    focus = "list",
                    current = false,
                    layout = {
                        layout = {
                            width = 0.3,
                        },
                        preview = false,
                    },
                })
            end,
            desc = "Search buffers",
        },
        {
            "<C-p>",
            function()
                Snacks.picker.files({
                    layout = "vertical",
                })
            end,
            desc = "Search files",
        },
        {
            "<leader>/",
            function()
                Snacks.picker.grep()
            end,
            desc = "Live grep",
        },
        {
            "<leader>sr",
            function()
                Snacks.picker.resume()
            end,
            desc = "Resume search",
        },
        {
            "<leader>ss",
            function()
                Snacks.picker.grep_word({ focus = "list" })
            end,
            desc = "Grep current word",
        },
        {
            "<leader>sh",
            function()
                Snacks.picker.help()
            end,
            desc = "Search help",
        },
        {
            "<leader>so",
            function()
                Snacks.picker.recent()
            end,
            desc = "Recent files",
        },
        {
            "<leader>si",
            function()
                Snacks.picker.icons({
                    layout = "select",
                })
            end,
            desc = "Search icons",
        },
        {
            "<leader>sk",
            function()
                Snacks.picker.keymaps()
            end,
            desc = "Search keymaps",
        },
        {
            "<leader>sd",
            function()
                Snacks.picker.diagnostics({ focus = "list" })
            end,
            desc = "Diagnositcs",
        },
        {
            "<leader>sm",
            function()
                Snacks.picker.marks({ focus = "list" })
            end,
            desc = "Search marks",
        },
        {
            "<leader>sgb",
            function()
                Snacks.picker.git_branches({
                    layout = "select",
                    focus = "list",
                })
            end,
            desc = "Search git branches",
        },
        {
            "<leader>sgl",
            function()
                Snacks.picker.git_log({ focus = "list" })
            end,
            desc = "Search git log",
        },
        {
            "<leader>sl",
            function()
                Snacks.picker.lsp_symbols()
            end,
            desc = "Search lsp symbols",
        },
    },
}
