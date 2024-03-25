-- Show more info for Diffview
-- so that we can be very sure about the branch and commit
-- in each panel
local function extract_commit_hash(path)
    local _, j = string.find(path, ".git/")
    if not j then
        return nil
    end
    local hash, len = {}, math.min(string.len(path), j + 7)
    for idx = j + 1, len, 1 do
        local ch = string.sub(path, idx, idx)
        if ch ~= "/" then
            hash[idx - j] = ch
        end
    end
    return table.concat(hash)
end

local function get_branch(hash)
    local obj = vim.system({ "git", "branch", "-l", "--contains", hash }, { text = true }):wait()
    if not obj or obj.code ~= 0 then
        return ""
    end
    for line in obj.stdout:gmatch("([^\n]*)\n?") do
        for i = 1, string.len(line), 1 do
            local ch = string.sub(line, i, i)
            if ch:match("%s") == nil and ch ~= "*" then
                return string.sub(line, i)
            end
        end
    end
    return ""
end

local function extract_gitinfo()
    local fullpath = vim.fn.expand("%")
    local diffview, panels = "diffview:///", "panels"
    local d_len, p_len = string.len(diffview), string.len(panels)

    if string.sub(fullpath, 1, d_len) == diffview then
        if string.sub(fullpath, d_len + 1, p_len + d_len) ~= panels then
            local hash = extract_commit_hash(fullpath)
            if hash then
                local branch = get_branch(hash)
                return "[" .. branch .. ":" .. hash .. "]"
            end
        end
    end
    return ""
end

-- 99% of the time it is utf-8, better save some space not showing it
local function encoding_hide_utf8()
    if vim.bo.fenc == "utf-8" or vim.go.enc == "utf-8" then
        return ""
    end
    return vim.bo.fenc or vim.go.enc
end

-- 99% of the time it is unix, better save some space not showing it
local function ff_hide_linux()
    if vim.bo.fileformat == "unix" then
        return ""
    end
    return vim.bo.fileformat
end

return {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons", opt = true },
    config = function()
        local lualine = require("lualine")
        -- local utils = require("lualine.utils.utils")
        -- local colors = {
        --     normal = utils.extract_color_from_hllist("bg", { "PmenuSel", "PmenuThumb", "TabLineSel" }, "#000000"),
        --     insert = utils.extract_color_from_hllist("fg", { "String", "MoreMsg" }, "#000000"),
        --     replace = utils.extract_color_from_hllist("fg", { "Number", "Type" }, "#000000"),
        --     visual = utils.extract_color_from_hllist("fg", { "Special", "Boolean", "Constant" }, "#000000"),
        --     command = utils.extract_color_from_hllist("fg", { "Identifier" }, "#000000"),
        --     back1 = utils.extract_color_from_hllist("bg", { "Normal", "StatusLineNC" }, "#000000"),
        --     fore = utils.extract_color_from_hllist("fg", { "Normal", "StatusLine" }, "#000000"),
        --     back2 = utils.extract_color_from_hllist("bg", { "StatusLine" }, "#000000"),
        -- }
        local config = {
            options = {
                icons_enabled = vim.opt.termguicolors,
                component_separators = { left = "", right = "" },
                section_separators = { left = "", right = "" },
                -- theme = "nord",
                --    	component_separators = '',
                --    	section_separators = '',
            },
            sections = {
                lualine_c = {
                    {
                        extract_gitinfo,
                        color = { bg = "#424250", fg = "#89abe4", gui = "none" },
                    },
                    {
                        "filename",
                    },
                },
                lualine_x = {
                    { encoding_hide_utf8 },
                    { ff_hide_linux },
                    "filetype",
                },
            },
            inactive_sections = {
                lualine_c = {
                    {
                        extract_gitinfo,
                    },
                    {
                        "filename",
                    },
                },
            },
        }
        lualine.setup(config)
    end,
}
