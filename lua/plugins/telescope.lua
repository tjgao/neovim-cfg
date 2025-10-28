local builtin

local function buffer_search()
    local opts = { sort_lastused = true, sort_mru = true }
    opts.prompt_title = "Buffers"
    opts.previewer = true
    opts.layout_config = { height = 0.5, width = 0.6 }
    builtin.buffers(opts)
end

local function repo_file_search(fn, folder)
    if folder == nil or folder == "" then
        folder = vim.fn.getcwd()
    end
    local opts = {}
    local files = "Git files: "
    opts.prompt_title = files .. folder
    opts.find_command = { "git", "ls-files" }
    if fn ~= nil and fn ~= "" then
        opts.default_text = fn
    end
    opts.previewer = false
    opts.layout_config = { height = 0.5, width = 0.4 }
    builtin.find_files(opts)
end

local function regular_file_search(fn, folder)
    if folder == nil or folder == "" then
        folder = vim.fn.getcwd()
    end
    local opts = {}
    local files = "Files: "
    opts.prompt_title = files .. folder
    opts.find_command = { "fd" }
    opts.no_ignore = true
    if fn ~= nil and fn ~= "" then
        opts.default_text = fn
    end
    opts.previewer = false
    opts.layout_config = { height = 0.5, width = 0.4 }
    builtin.find_files(opts)
end

local function nvim_file_search()
    local opts = {}
    local cwd = vim.fn.stdpath("config")
    opts.prompt_title = "NeoVim files: " .. cwd
    opts.previewer = false
    opts.layout_config = { height = 0.5, width = 0.4 }
    opts.cwd = cwd
    builtin.find_files(opts)
end

local function keymap(mode, keys, f, opts)
    if opts.desc ~= nil and opts.desc ~= "" then
        opts.desc = opts.desc .. " [Telescope]"
    end
    vim.keymap.set(mode, keys, f, opts)
end

M = {
    {
        "nvim-telescope/telescope.nvim",
        dependencies = {
            { "nvim-lua/plenary.nvim" },
            { "nvim-telescope/telescope-rg.nvim" },
            { "nvim-telescope/telescope-symbols.nvim" },
            { "nvim-telescope/telescope-live-grep-args.nvim" },
        },
        config = function()
            local telescope = require("telescope")
            local lga_actions = require("telescope-live-grep-args.actions")
            telescope.setup({
                auto_quoting = true,
                mappings = {
                    i = {
                        ["<C-k>"] = lga_actions.quote_prompt(),
                        ["<C-i>"] = lga_actions.quote_prompt({ postfix = " --iglob " }),
                        ["<C-space>"] = lga_actions.to_fuzzy_refine,
                    },
                },
            })
            telescope.load_extension("live_grep_args")

            builtin = require("telescope.builtin")
            local live_grep_args = telescope.extensions.live_grep_args

            local function grep_in_git_files()
                local live_grep_args_shortcut = require("telescope-live-grep-args.shortcuts")
                local is_git_repo = vim.fn.system("git rev-parse --is-inside-work-tree 2> /dev/null") == "true\n"
                if is_git_repo then
                    local git_files = vim.fn.systemlist("git ls-files")
                    live_grep_args_shortcut.grep_word_under_cursor({
                        grep_open_files = false,
                        search_dirs = git_files,
                    })
                else
                    live_grep_args_shortcut.grep_word_under_cursor()
                end
            end

            keymap("n", "<C-p>", regular_file_search, { desc = "Search file in current folder" })
            keymap("n", "<leader>p", repo_file_search, { desc = "Search file in repo" })
            keymap("n", "<leader>b", function()
                buffer_search()
            end, { desc = "Search buffers" })
            keymap("n", "<leader>/", function()
                live_grep_args.live_grep_args()
            end, { desc = "Live rg search" })
            keymap("n", "<leader>sh", builtin.help_tags, { desc = "Search help" })
            keymap("n", "<leader>ss", grep_in_git_files, { desc = "Search the word under cursor" })
            keymap("n", "<leader>sk", builtin.keymaps, { desc = "Search keymaps" })
            keymap("n", "<leader>sd", builtin.diagnostics, { desc = "Search diagnostics" })
            keymap("n", "<leader>so", builtin.oldfiles, { desc = "Search recent files" })
            keymap("n", "<leader>sn", nvim_file_search, { desc = "Search neovim files" })
            keymap("n", "<leader><leader>", builtin.builtin, { desc = "Search in Telescope" })
            keymap("n", "<leader>sr", builtin.resume, { desc = "Search resume" })
            keymap("n", "<leader>gc", ":Telescope git_branches<CR>", { desc = "Git branches" })
            -- keymap("n", "<leader>/", function()
            --     -- You can pass additional configuration to telescope to change theme, layout, etc.
            --     builtin.current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
            --         winblend = 10,
            --         -- previewer = false,
            --     }))
            -- end, { desc = "Fuzzy search in current buffer" })
        end,
    },
    {
        "nvim-telescope/telescope-ui-select.nvim",
        config = function()
            local trouble = require("trouble.sources.telescope")
            local actions = require("telescope.actions")
            local smart_send_q = function(prompt_buf)
                actions.smart_send_to_qflist(prompt_buf)
                vim.g.last_trouble_mode = "qflist"
                vim.cmd("copen")
                -- vim.cmd("Trouble qflist toggle focus=true")
            end
            local smart_send_l = function(prompt_buf)
                actions.smart_send_to_loclist(prompt_buf)
                vim.g.last_trouble_mode = "loclist"
                vim.cmd("lopen")
                -- vim.cmd("Trouble loclist toggle focus=true")
            end
            require("telescope").setup({
                extensions = {
                    ["ui-select"] = {
                        require("telescope.themes").get_dropdown({}),
                    },
                },
                defaults = {
                    mappings = {
                        i = {
                            ["<c-t>"] = function(prompt_buf)
                                vim.g.last_trouble_mode = "telescope"
                                trouble.open(prompt_buf, { focus = true })
                            end,
                            ["<c-q>"] = smart_send_q,
                            ["<c-l>"] = smart_send_l,
                        },
                        n = {
                            ["<c-t>"] = function(prompt_buf)
                                vim.g.last_trouble_mode = "telescope"
                                trouble.open(prompt_buf, { focus = true })
                            end,
                            -- ["<c-t>"] = trouble.open,
                            ["<c-q>"] = smart_send_q,
                            ["<c-l>"] = smart_send_l,
                        },
                    },
                },
            })
            require("telescope").load_extension("ui-select")
        end,
    },
    {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
        config = function()
            local t = require("telescope")
            t.setup({
                extensions = {
                    fzf = {
                        fuzzy = true,
                        override_generic_sorter = true,
                        override_file_sorter = true,
                        case_mode = "smart_case",
                    },
                },
            })
            t.load_extension("fzf")
        end,
    },
}

return M
