local git_branches = require("users.snacks.git_branches")
local git_log = require("users.snacks.git_log")
local git_rg = require("users.snacks.git_rg")
local picker_actions = require("users.snacks.picker_actions")

return {
    "folke/snacks.nvim",
    lazy = false,
    ---@diagnostic disable-next-line: undefined-doc-name
    ---@type snacks.Config
    opts = {
        bigfile = { enabled = true },
        explorer = { enabled = false },
        image = {
            enabled = true,
            doc = {
                inline = false,
                float = true,
            },
        },
        notifier = {
            enabled = true,
        },
        picker = {
            enabled = true,
            layout = {
                backdrop = true,
            },
            git_branches = {
                all = false,
            },
            sources = {
                select = {
                    kinds = {
                        overseer_template = {
                            focus = "list",
                        },
                        overseer_task = {
                            focus = "list",
                        },
                        overseer_task_options = {
                            focus = "list",
                        },
                    },
                },
            },
            matcher = { frecency = true },
            formatters = {
                file = {
                    filename_first = true,
                },
            },
            previewers = {
                diff = {
                    style = "fancy",
                },
            },
            win = {
                input = {
                    keys = {
                        ["<S-l>"] = { "focus_preview", mode = { "n" } },
                        ["<S-h>"] = { "focus_preview", mode = { "n" } },
                        ["Q"] = { "loclist", mode = { "n" } },
                        ["<C-j>"] = { "preview_scroll_down", mode = { "i", "n" } },
                        ["<C-k>"] = { "preview_scroll_up", mode = { "i", "n" } },
                        ["<C-h>"] = { "preview_scroll_left", mode = { "i", "n" } },
                        ["<C-l>"] = { "preview_scroll_right", mode = { "i", "n" } },
                    },
                },
                list = {
                    keys = {
                        ["<S-l>"] = { "focus_preview", mode = { "n" } },
                        ["<S-h>"] = { "focus_preview", mode = { "n" } },
                        ["Q"] = { "loclist", mode = { "n" } },
                    },
                },
                preview = {
                    keys = {
                        ["<S-h>"] = { "focus_list", mode = { "n" } },
                        ["<S-l>"] = { "focus_list", mode = { "n" } },
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
                { section = "recent_files", title = "Recent Files", cwd = true },
                { section = "startup" },
            },
        },
    },
    keys = {
        {
            "<leader><space>",
            function()
                require("snacks").picker()
            end,
            desc = "Snacks Menu",
        },
        {
            "<leader>p",
            function()
                require("snacks").picker.pick({
                    source = "git_files",
                    layout = {
                        preset = "vertical",
                    },
                    actions = {
                        get_path = picker_actions.get_path,
                        copy_path = picker_actions.copy_path,
                        copy_filename = picker_actions.copy_filename,
                        open_in_tab = picker_actions.open_in_tab,
                    },
                    win = {
                        list = {
                            keys = {
                                ["."] = {
                                    "get_path",
                                    mode = { "n" },
                                },
                                [","] = {
                                    "copy_path",
                                    mode = { "n" },
                                },
                                [";"] = {
                                    "copy_filename",
                                    mode = { "n" },
                                },
                                ["T"] = {
                                    "open_in_tab",
                                    mode = { "n" },
                                },
                            },
                        },
                        input = {
                            keys = {
                                ["."] = {
                                    "get_path",
                                    mode = { "n" },
                                },
                                [","] = {
                                    "copy_path",
                                    mode = { "n" },
                                },
                                [";"] = {
                                    "copy_filename",
                                    mode = { "n" },
                                },
                                ["T"] = {
                                    "open_in_tab",
                                    mode = { "n" },
                                },
                            },
                        },
                    },
                })
            end,
            desc = "Search git files",
        },
        {
            "<leader>b",
            function()
                require("snacks").picker.pick({
                    focus = "list",
                    source = "buffers",
                    current = false,
                    layout = {
                        layout = {
                            height = 0.5,
                            width = 40,
                        },
                        preset = "vertical",
                        preview = false,
                    },
                })
            end,
            desc = "Search buffers",
        },
        {
            "<C-p>",
            function()
                require("snacks").picker.pick({
                    source = "files",
                    layout = {
                        preset = "vertical",
                    },
                    actions = {
                        get_path = picker_actions.get_path,
                        copy_path = picker_actions.copy_path,
                        copy_filename = picker_actions.copy_filename,
                        open_in_tab = picker_actions.open_in_tab,
                    },
                    win = {
                        list = {
                            keys = {
                                ["."] = {
                                    "get_path",
                                    mode = { "n" },
                                },
                                [","] = {
                                    "copy_path",
                                    mode = { "n" },
                                },
                                [";"] = {
                                    "copy_filename",
                                    mode = { "n" },
                                },
                                ["T"] = {
                                    "open_in_tab",
                                    mode = { "n" },
                                },
                            },
                        },
                        input = {
                            keys = {
                                ["."] = {
                                    "get_path",
                                    mode = { "n" },
                                },
                                [","] = {
                                    "copy_path",
                                    mode = { "n" },
                                },
                                [";"] = {
                                    "copy_filename",
                                    mode = { "n" },
                                },
                                ["T"] = {
                                    "open_in_tab",
                                    mode = { "n" },
                                },
                            },
                        },
                    },
                })
            end,
            desc = "Search files",
        },
        {
            "<leader>/",
            function()
                git_rg.git_rg({
                    formatters = {
                        file = {
                            filename_first = true,
                            min_width = 100,
                        },
                    },
                })
            end,
            desc = "Git live grep",
        },
        {
            "<leader>?",
            function()
                git_rg.grep({
                    formatters = {
                        file = {
                            filename_first = true,
                            min_width = 100,
                        },
                    },
                })
            end,
            desc = "Live grep",
        },
        {
            "<leader>sr",
            function()
                require("snacks").picker.resume()
            end,
            desc = "Resume search",
        },
        {
            "<leader>ss",
            function()
                git_rg.git_rg({
                    focus = "list",
                    formatters = {
                        file = {
                            filename_first = true,
                            min_width = 100,
                        },
                    },
                    regex = false,
                    live = false,
                    search = function(picker)
                        return picker:word()
                    end,
                    supports_live = true,
                })
            end,
            desc = "Grep current word in git files",
        },
        {
            "<leader>sS",
            function()
                git_rg.grep_word({
                    focus = "list",
                    formatters = {
                        file = {
                            filename_first = true,
                            min_width = 100,
                        },
                    },
                })
            end,
            desc = "Grep current word",
        },
        {
            "<leader>sh",
            function()
                require("snacks").picker.help()
            end,
            desc = "Search help",
        },
        {
            "<leader>so",
            function()
                require("snacks").picker.recent()
            end,
            desc = "Recent files",
        },
        {
            "<leader>si",
            function()
                require("snacks").picker.icons({
                    layout = "select",
                })
            end,
            desc = "Search icons",
        },
        {
            "<leader>sk",
            function()
                require("snacks").picker.keymaps()
            end,
            desc = "Search keymaps",
        },
        {
            "<leader>sd",
            function()
                require("snacks").picker.diagnostics({ focus = "list" })
            end,
            desc = "Diagnositcs",
        },
        {
            "<leader>sm",
            function()
                require("snacks").picker.marks({ focus = "list" })
            end,
            desc = "Search marks",
        },
        {
            "<leader>sgb",
            function()
                git_branches.open_git_branches_picker()
            end,
            desc = "Search git branches",
        },
        {
            "<leader>sq",
            function()
                require("snacks").picker.qflist()
            end,
            desc = "Search quickfix",
        },
        {
            "<leader>sl",
            function()
                require("snacks").picker.loclist()
            end,
            desc = "Search loclist",
        },
        {
            "<leader>sgl",
            function()
                git_log.open()
            end,
            desc = "Search git log",
        },
        {
            "<leader>l",
            function()
                require("snacks").picker.lsp_symbols()
            end,
            desc = "Search lsp symbols",
        },
    },
}
