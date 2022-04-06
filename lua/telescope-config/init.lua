local telescope = require('telescope')
local builtin = require('telescope.builtin')
local utils = require('telescope.utils')
local finders = require('telescope.finders')

telescope.setup{}

local live_grep_raw = telescope.extensions.live_grep_raw.live_grep_raw

-- local pickers = require('telescope.pickers')

local M = {}

-- @todo
-- 1. search in git files only
-- 2. specify multiple folders to search strings

local function check_git_folder(folder)
    local cmd = { 'git' }
    local args = { 'rev-parse', '--is-inside-work-tree' }
    if folder == nil or folder == '' then
        table.insert(cmd, '-C')
        table.insert(cmd, folder)
    end
    for _, v in pairs(args) do
        table.insert(cmd, v)
    end
    local _, ret, _ = utils.get_os_command_output(cmd)
    return ret == 0
end

function M.word_search(word, folder)
    if word == nil or word == '' then
        word = vim.fn.expand '<cword>'
    end
    if folder == nil or folder == '' then
        folder = vim.fn.getcwd()
    end
    live_grep_raw {
        prompt_title = 'Search in: ' .. folder,
        -- search = folder,
        shorten_path = true,
        default_text = word
    }
end


-- function M.word_search_gitfiles(word)
--     if word == nil or word == '' then
--         word = vim.fn.expand '<cword>'
--     end
-- end


-- function M.file_search(folder, fn)
function M.file_search(fn)
    local folder = nil
    if folder == nil or folder == '' then
        folder = vim.fn.getcwd()
    end
    local opts = {}
    opts.prompt_title = 'Search in: ' .. folder
    opts.search = folder
    if fn ~= nil and fn ~= '' then
        opts.default_text = fn
    end
    builtin.find_files(opts)
end

-- function M.file_search_gitfiles(fn)
--     local _, ret, stderr = utils.get_os_command_output({ 'git', 'rev-parse', '--is-inside-work-tree'})
-- end

return M;
