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
                blackdrop = true,
            },
            matcher = { frecency = true },
            formatters = {
                file = {
                    filename_first = true,
                },
            },
            previewer = {
                diff = {
                    style = "syntax",
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
                Snacks.picker.git_files()
            end,
            desc = "Search git files",
        },
        {
            "<leader>b",
            function()
                Snacks.picker.buffers({
                    on_show = function()
                        vim.cmd.stopinsert()
                    end,
                    current = false,
                })
            end,
            desc = "Search buffers",
        },
        {
            "<C-p>",
            function()
                Snacks.picker.files()
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
                Snacks.picker.icons()
            end,
            desc = "Search icons",
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
    },
}
