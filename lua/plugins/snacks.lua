local function get_git_root()
    local cwd = vim.fn.expand("%:p:h")
    if cwd == "" then
        cwd = vim.uv.cwd() or "."
    end

    local proc = vim.system({ "git", "-C", cwd, "rev-parse", "--show-toplevel" }, { text = true }):wait()
    if proc.code ~= 0 then
        return nil
    end

    return vim.trim(proc.stdout)
end

local function get_git_tracked_files(root)
    local proc = vim.system({ "git", "-C", root, "grep", "-I", "--name-only", "-z", "-e", "." }, { text = true }):wait()
    if proc.code ~= 0 then
        proc = vim.system({ "git", "-C", root, "ls-files", "-z" }, { text = true }):wait()
        if proc.code ~= 0 then
            return {}
        end
    end

    local files = {}
    for file in proc.stdout:gmatch("([^%z]+)") do
        files[#files + 1] = file
    end
    return files
end

local function strip_quotes(s)
    local first = s:sub(1, 1)
    local last = s:sub(-1)
    if (first == '"' and last == '"') or (first == "'" and last == "'") then
        return s:sub(2, -2)
    end
    return s
end

local function parse_query_filters(search)
    local util = require("snacks.picker.util")
    local text, args = util.parse(search)
    local keep = {}
    local types = {}

    local i = 1
    while i <= #args do
        local arg = args[i]
        local t = arg:match("^%-t=(.+)$") or arg:match("^%-%-type=(.+)$")
        if t then
            types[#types + 1] = strip_quotes(t)
        elseif arg == "-t" or arg == "--type" then
            if args[i + 1] then
                types[#types + 1] = strip_quotes(args[i + 1])
                i = i + 1
            end
        else
            keep[#keep + 1] = arg
        end
        i = i + 1
    end

    if #keep == 0 then
        return {
            search = text,
            types = types,
            has_rg_args = false,
        }
    end
    return {
        search = text .. " -- " .. table.concat(keep, " "),
        types = types,
        has_rg_args = true,
    }
end

local function filter_files_by_types(files, types)
    if #types == 0 then
        return files
    end

    local allowed = {}
    for _, t in ipairs(types) do
        if t ~= "all" and t ~= "" then
            allowed[t] = true
        end
    end
    if vim.tbl_isempty(allowed) then
        return files
    end

    local filtered = {}
    for _, file in ipairs(files) do
        local ext = file:match("%.([%w_+-]+)$")
        if ext and allowed[ext] then
            filtered[#filtered + 1] = file
        end
    end
    return filtered
end

local function git_rg(opts)
    local snacks = require("snacks")
    local root = get_git_root()
    if not root then
        return snacks.picker.git_grep(opts)
    end

    local files = get_git_tracked_files(root)
    if #files == 0 then
        return snacks.picker.git_grep(opts)
    end

    return snacks.picker.pick(vim.tbl_deep_extend("force", {
        source = "grep",
        cwd = root,
        dirs = files,
        finder = function(fopts, ctx)
            local parsed = parse_query_filters(ctx.filter.search)
            local has_base_rg_opts = opts
                and (
                    (opts.args and #opts.args > 0)
                    or opts.ft ~= nil
                    or opts.glob ~= nil
                    or opts.regex == false
                )

            if #parsed.types == 0 and not parsed.has_rg_args and not has_base_rg_opts then
                local git_finder = require("snacks.picker.source.git").grep
                return git_finder(vim.tbl_deep_extend("force", {
                    cwd = root,
                    need_search = true,
                    untracked = false,
                    submodules = false,
                }, opts or {}), ctx)
            end

            local filtered_files = filter_files_by_types(files, parsed.types)
            if #filtered_files == 0 then
                return function() end
            end

            local nctx = ctx:clone()
            nctx.filter = nctx.filter:clone()
            nctx.filter.search = parsed.search

            local next_opts = vim.tbl_deep_extend("force", fopts, { dirs = filtered_files })
            return require("snacks.picker.source.grep").grep(next_opts, nctx)
        end,
        args = { "--no-messages", "--no-binary" },
        title = "Git Rg",
        supports_live = true,
        live = true,
    }, opts or {}))
end

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
                all = true,
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
                    current = false,
                    source = "buffers",
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
                git_rg({
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
                git_rg({
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
                require("snacks").picker.pick({
                    focus = "list",
                    source = "git_branches",
                    layout = {
                        preset = "select",
                        -- layout = { min_width = 120, max_width = 160 },
                    },
                    format = function(item, picker)
                        local Snacks = require("snacks")
                        local a = Snacks.picker.util.align
                        local ret = {}
                        ret[#ret + 1] = item.current and { a("", 2), "SnacksPickerGitBranchCurrent" } or { a("", 2) }

                        local w = 60 -- branch column width
                        if item.detached then
                            ret[#ret + 1] = { a("(detached HEAD)", w, { truncate = true }), "SnacksPickerGitDetached" }
                        else
                            ret[#ret + 1] = { a(item.branch, w, { truncate = true }), "SnacksPickerGitBranch" }
                        end

                        ret[#ret + 1] = { " " }
                        Snacks.picker.highlight.extend(ret, Snacks.picker.format.git_log(item, picker))
                        return ret
                    end,
                    actions = {
                        diffview_d = function(picker, item)
                            vim.cmd(("DiffviewOpen %s^!"):format(item.commit))
                            picker:close()
                        end,
                        diffview_D = function(picker, item)
                            vim.cmd(("DiffviewOpen %s"):format(item.commit))
                            picker:close()
                        end,
                        diffview_x = function(picker, item)
                            picker:close()
                            local fname = vim.api.nvim_buf_get_name(0)
                            vim.cmd(("DiffviewOpen %s HEAD -- %s"):format(item.commit, fname))
                        end,
                        commit_to_cmd = function(picker, item)
                            picker:close()
                            local home = vim.api.nvim_replace_termcodes("<Home>", true, false, true)
                            vim.api.nvim_feedkeys(":" .. item.commit .. home, "n", false)
                        end,
                        commit_to_reg = function(picker, item)
                            picker:close()
                            -- yank
                            vim.fn.setreg('"', item.commit)
                            vim.fn.setreg("0", item.commit)
                            vim.fn.setreg("+", item.commit) -- Also put in clipboard
                        end,
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
            desc = "Search git branches",
        },
        {
            "<leader>sgl",
            function()
                require("snacks").picker.pick({
                    focus = "list",
                    source = "git_log",
                    actions = {
                        diffview_d = function(picker, item)
                            vim.cmd(("DiffviewOpen %s^!"):format(item.commit))
                            picker:close()
                        end,
                        diffview_D = function(picker, item)
                            vim.cmd(("DiffviewOpen %s"):format(item.commit))
                            picker:close()
                        end,
                        diffview_x = function(picker, item)
                            picker:close()
                            local fname = vim.api.nvim_buf_get_name(0)
                            vim.cmd(("DiffviewOpen %s HEAD -- %s"):format(item.commit, fname))
                        end,
                        commit_to_cmd = function(picker, item)
                            picker:close()
                            local home = vim.api.nvim_replace_termcodes("<Home>", true, false, true)
                            vim.api.nvim_feedkeys(":" .. item.commit .. home, "n", false)
                        end,
                        commit_to_reg = function(picker, item)
                            picker:close()
                            -- yank
                            vim.fn.setreg('"', item.commit)
                            vim.fn.setreg("0", item.commit)
                            vim.fn.setreg("+", item.commit) -- Also put in clipboard
                        end,
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
