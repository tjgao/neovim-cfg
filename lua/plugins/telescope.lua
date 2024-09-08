local builtin

local function buffer_search()
    local opts = {}
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
        },
        config = function()
            builtin = require("telescope.builtin")
            keymap("n", "<C-p>", regular_file_search, { desc = "Search file in current folder" })
            keymap("n", "<leader>p", repo_file_search, { desc = "Search file in repo" })
            keymap("n", "<leader>b", buffer_search, { desc = "Search buffers" })
            keymap("n", "<leader>/", builtin.live_grep, { desc = "Live rg search" })
            keymap("n", "<leader>sh", builtin.help_tags, { desc = "Search help" })
            keymap("n", "<leader>sk", builtin.keymaps, { desc = "Search keymaps" })
            keymap("n", "<leader>ss", builtin.grep_string, { desc = "Search any word" })
            keymap("n", "<leader>sd", builtin.diagnostics, { desc = "Search diagnostics" })
            keymap("n", "<leader>so", builtin.oldfiles, { desc = "Search recent files" })
            keymap("n", "<leader>sb", builtin.buffers, { desc = "Search buffers" })
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
            local smart_send = function(prompt_buf)
                actions.smart_send_to_qflist(prompt_buf)
                vim.cmd("copen")
            end
            local setting = {
                mappings = {
                    i = { ["<c-f>"] = actions.to_fuzzy_refine },
                },
            }
            require("telescope").setup({
                pickers = {
                    live_grep = setting,
                },
                extensions = {
                    ["ui-select"] = {
                        require("telescope.themes").get_dropdown({}),
                    },
                },
                defaults = {
                    mappings = {
                        i = {
                            ["<c-t>"] = trouble.open,
                            ["<c-q>"] = smart_send,
                        },
                        n = {
                            ["<c-t>"] = trouble.open,
                            ["<c-q>"] = smart_send,
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
