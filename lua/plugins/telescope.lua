-- local telescope = require('telescope')
-- local builtin = require('telescope.builtin')
-- local utils = require('telescope.utils')
-- local finders = require('telescope.finders')

-- local live_grep_raw = telescope.extensions.live_grep_args.live_grep_args

-- telescope.load_extension "fzf"

-- telescope.load_extensions "zoxide"

-- local pickers = require('telescope.pickers')

-- @todo
-- 1. search in git files only
-- 2. specify multiple folders to search strings

local builtin
-- local utils
-- local function check_git_folder(folder)
--     local cmd = { 'git' }
--     local args = { 'rev-parse', '--is-inside-work-tree' }
--     if folder ~= nil or folder ~= '' then
--         table.insert(cmd, '-C')
--         table.insert(cmd, folder)
--     end
--     for _, v in pairs(args) do
--         table.insert(cmd, v)
--     end
--     local _, ret, _ = utils.get_os_command_output(cmd)
--     return ret == 0
-- end
--
-- local function word_search(word, folder)
--     if word == nil or word == '' then
--         word = vim.fn.expand '<cword>'
--     end
--     if folder == nil or folder == '' then
--         folder = vim.fn.getcwd()
--     end
--     live_grep_raw {
--         prompt_title = 'Search in: ' .. folder,
--         -- search = folder,
--         shorten_path = true,
--         default_text = word
--     }
-- end
--
--
-- -- search files in the current working directory
-- -- if we are in a repo directory, search git files only
-- -- otherwise degrade to a normal file search
-- local function file_search(fn, folder)
--     if folder == nil or folder == '' then
--         folder = vim.fn.getcwd()
--     end
--     local files = 'Files: '
--     local opts = {}
--     if check_git_folder(folder) then
--         opts.find_command = {'git', 'ls-files'}
--         files = 'Git files: '
--     end
--     opts.prompt_title = files .. folder
--     if fn ~= nil and fn ~= '' then
--         opts.default_text = fn
--     end
--     builtin.find_files(opts)
-- end

local function repo_file_search(fn, folder)
    if folder == nil or folder == "" then
        folder = vim.fn.getcwd()
    end
    local opts = {}
    local files = "Git files:"
    opts.prompt_title = files .. folder
    opts.find_command = { "git", "ls-files" }
    if fn ~= nil and fn ~= "" then
        opts.default_text = fn
    end
    builtin.find_files(opts)
end

local function regular_file_search(fn, folder)
    if folder == nil or folder == "" then
        folder = vim.fn.getcwd()
    end
    local opts = {}
    local files = "Files:"
    opts.prompt_title = files .. folder
    if fn ~= nil and fn ~= "" then
        opts.default_text = fn
    end
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
            --      {'nvim-telescope/telescope-fzf-native.nvim', run = 'make' }
        },
        config = function()
            builtin = require("telescope.builtin")
            keymap("n", "<C-p>", regular_file_search, { desc = "Search file in current folder" })
            keymap("n", "<leader>p", repo_file_search, { desc = "Search file in repo" })
            keymap("n", "<leader>sg", builtin.live_grep, { desc = "Live rg search" })
            keymap("n", "<leader>sh", builtin.help_tags, { desc = "Search help" })
            keymap("n", "<leader>sk", builtin.keymaps, { desc = "Search keymaps" })
            keymap("n", "<leader>ss", builtin.grep_string, { desc = "Search current word" })
            keymap("n", "<leader>sd", builtin.diagnostics, { desc = "Search diagnostics" })
            keymap("n", "<leader>so", builtin.oldfiles, { desc = "Search recent files" })
            keymap("n", "<leader>sb", builtin.buffers, { desc = "Search buffers" })
            keymap("n", "<leader>sn", function()
                builtin.find_files({ cwd = vim.fn.stdpath("config") })
            end, { desc = "Search neovim files" })
            keymap("n", "<leader><leader>", builtin.builtin, { desc = "Search in Telescope" })
            keymap("n", "<leader>sr", builtin.resume, { desc = "Search resume" })

            -- Slightly advanced example of overriding default behavior and theme
            keymap("n", "<leader>/", function()
                -- You can pass additional configuration to telescope to change theme, layout, etc.
                builtin.current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
                    winblend = 10,
                    previewer = false,
                }))
            end, { desc = "Fuzzy search in current buffer" })
        end,
    },
    {
        "nvim-telescope/telescope-ui-select.nvim",
        config = function()
            local trouble = require("trouble.providers.telescope")
            local actions = require("telescope.actions")
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
                        i = { ["<c-t>"] = trouble.smart_open_with_trouble }, -- send results to trouble
                        n = { ["<c-t>"] = trouble.smart_open_with_trouble },
                    },
                },
            })
            require("telescope").load_extension("ui-select")
        end,
    },
}

return M
