local git_actions = require("users.snacks.git_actions")
local git_branches = require("users.snacks.git_branches")
local git_rg = require("users.snacks.git_rg")

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
                        ["<C-j>"] = { "preview_scroll_down", mode = { "i", "n" } },
                        ["<C-k>"] = { "preview_scroll_up", mode = { "i", "n" } },
                        ["<C-h>"] = { "preview_scroll_left", mode = { "i", "n" } },
                        ["<C-l>"] = { "preview_scroll_right", mode = { "i", "n" } },
                    },
                },
                list = {
                    keys = {
                        ["<S-l>"] = { "focus_preview", mode = { "n" } },
                    },
                },
                preview = {
                    keys = {
                        ["<S-h>"] = { "focus_list", mode = { "n" } },
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
                        get_path = function(picker, item)
                            picker:close()
                            local home = vim.api.nvim_replace_termcodes("<Home>", true, false, true)
                            vim.api.nvim_feedkeys(":" .. item.file .. home, "n", false)
                        end,
                        copy_path = function(picker, item)
                            picker:close()
                            -- yank
                            vim.fn.setreg('"', item.file)
                            vim.fn.setreg("0", item.file)
                            vim.fn.setreg("+", item.file) -- Also put in clipboard
                        end,
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
                        get_path = function(picker, item)
                            picker:close()
                            local home = vim.api.nvim_replace_termcodes("<Home>", true, false, true)
                            vim.api.nvim_feedkeys(":" .. item.file .. home, "n", false)
                        end,
                        copy_path = function(picker, item)
                            picker:close()
                            -- yank
                            vim.fn.setreg('"', item.file)
                            vim.fn.setreg("0", item.file)
                            vim.fn.setreg("+", item.file) -- Also put in clipboard
                        end,
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
                require("snacks").picker.grep({
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
                require("snacks").picker.grep_word({
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
            "<leader>sgl",
            function()
                require("snacks").picker.pick({
                    focus = "list",
                    source = "git_log",
                    actions = {
                        diffview_d = git_actions.diffview_d,
                        diffview_D = git_actions.diffview_D,
                        diffview_x = git_actions.diffview_x,
                        commit_to_cmd = git_actions.commit_to_cmd,
                        commit_to_reg = git_actions.commit_to_reg,
                    },

                    win = {
                        list = {
                            keys = {
                                ["d"] = {
                                    "diffview_d",
                                    mode = { "n" },
                                },
                                ["D"] = {
                                    "diffview_D",
                                    mode = { "n" },
                                },
                                ["x"] = {
                                    "diffview_x",
                                    mode = { "n" },
                                },
                                ["."] = {
                                    "commit_to_cmd",
                                    mode = { "n" },
                                },
                                [","] = {
                                    "commit_to_reg",
                                    mode = { "n" },
                                },
                            },
                        },
                        input = {
                            keys = {
                                ["d"] = {
                                    "diffview_d",
                                    mode = { "n" },
                                },
                                ["D"] = {
                                    "diffview_D",
                                    mode = { "n" },
                                },
                                ["x"] = {
                                    "diffview_x",
                                    mode = { "n" },
                                },
                                ["."] = {
                                    "commit_to_cmd",
                                    mode = { "n" },
                                },
                                [","] = {
                                    "commit_to_reg",
                                    mode = { "n" },
                                },
                            },
                        },
                    },
                })
            end,
            desc = "Search git log",
        },
        {
            "<leader>sl",
            function()
                require("snacks").picker.lsp_symbols()
            end,
            desc = "Search lsp symbols",
        },
    },
}
