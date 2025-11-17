-- Show more info for Diffview
-- so that we can be very sure about the branch and commit
-- in each panel

local cache_size = 100
local GitInfoCache = {}
GitInfoCache.__index = GitInfoCache

function GitInfoCache:new()
    local obj = {}
    setmetatable(obj, GitInfoCache)
    obj.map = {}
    obj.keys = {}
    obj.cap = cache_size
    return obj
end

function GitInfoCache:__random_remove_one()
    local idx = math.random(1, #self.keys)
    self.map[self.keys[idx]] = nil
    table.remove(self.keys, idx)
end

function GitInfoCache:add(key, val)
    if not self.map[key] then
        if self.cap and #self.keys > self.cap then
            GitInfoCache.__random_remove_one(self)
        end
        table.insert(self.keys, key)
    end
    self.map[key] = val
end

function GitInfoCache:get(key)
    local v = self.map[key]
    if not v then
        return nil
    end
    return v
end

local function parse_path_hash(path)
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
    local ret = table.concat(hash)
    if ret == ":0:" then
        local obj = vim.system({ "git", "log", "--pretty=%h", "-n", "1" }, { text = true }):wait()
        if not obj or obj.code ~= 0 then
            return nil
        end
        return vim.trim(obj.stdout)
    end
    return ret
end

local function truncate_branch(branch)
    local len, maxl = string.len(branch), 13
    if len > maxl then
        return "..." .. string.sub(branch, len - maxl + 3)
    end
    return branch
end

-- we can cache the result to avoid calling git commands all the time
local commit_to_branch = GitInfoCache:new()
local commit_to_time = GitInfoCache:new()

local function get_commit_time(hash)
    local tm = commit_to_time:get(hash)
    if tm then
        return tm
    end
    local obj = vim.system(
        { "git", "show", "-s", "--date=format:'%Y%m%d %H:%M'", "--format=%cd", hash },
        { text = true }
    )
        :wait()
    if not obj or obj.code ~= 0 then
        return nil
    end
    local ret = vim.trim(obj.stdout):gsub("^'(.-)'$", "%1")
    commit_to_time:add(hash, ret)
    return ret
end

local function get_branch(hash)
    local info = commit_to_branch:get(hash)
    if info then
        return info
    end
    local obj = vim.system({ "git", "branch", "-l", "--contains", hash, "--sort=-committerdate" }, { text = true })
        :wait()
    if not obj or obj.code ~= 0 then
        return ""
    end
    for line in obj.stdout:gmatch("([^\n]*)\n?") do
        for i = 1, string.len(line), 1 do
            local ch = string.sub(line, i, i)
            if ch:match("%s") == nil and ch ~= "*" then
                local ret = truncate_branch(string.sub(line, i))
                commit_to_branch:add(hash, ret)
                return ret
            end
        end
    end
    return ""
end

local function extract_hash(path)
    local diffview, panels = "diffview:///", "panels"
    local d_len, p_len = string.len(diffview), string.len(panels)

    if string.sub(path, 1, d_len) == diffview then
        if string.sub(path, d_len + 1, p_len + d_len) ~= panels then
            return parse_path_hash(path)
        end
    end
    return nil
end

local function extract_gitinfo()
    local hash = extract_hash(vim.fn.expand("%"))
    if hash then
        return get_branch(hash) .. ":" .. hash
    end
    return ""
end

local function create_gitinfo_component()
    local gi_component = require("lualine.component"):extend()
    ---@diagnostic disable-next-line: unused-local
    gi_component.update_status = function(self, is_focused)
        return extract_gitinfo()
    end
    return gi_component
end

local function extract_commit_time()
    local hash = extract_hash(vim.fn.expand("%"))
    if hash then
        return get_commit_time(hash)
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

-- this should not be used for inactive case,
-- as it is using current window's width
local function hide_when_narrow_down()
    local width = vim.api.nvim_win_get_width(0)
    if width < 100 then
        return false
    end
    return true
end

-- this should not be used for inactive case,
-- as it is using current window's width

local function custom_mode()
    local mode = vim.fn.mode()
    local mode_map = {
        ["n"] = "N", -- Normal mode
        ["no"] = "O-PENDING",
        ["nov"] = "O-PENDING",
        ["noV"] = "O-PENDING",
        ["no "] = "O-PENDING",
        ["niI"] = "N",
        ["niR"] = "N",
        ["niV"] = "N",
        ["nt"] = "N",
        ["v"] = "V",
        ["V"] = "V",
        [" "] = "V",
        ["s"] = "S",
        ["S"] = "S",
        [" S"] = "S",
        ["i"] = "I",
        ["R"] = "R",
        ["Rv"] = "VR",
        ["c"] = "C",
        ["cv"] = "EX",
        ["ce"] = "EX",
        ["r"] = "R",
        ["rm"] = "MORE",
        ["r?"] = "CFM",
        ["!"] = "SH",
        ["t"] = "T",
    }
    return mode_map[mode] or mode -- Fallback to original mode if not mapped
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
        local gi_component = create_gitinfo_component()
        local config = {
            options = {
                icons_enabled = vim.opt.termguicolors,
                -- theme = "iceberg",
                component_separators = "",
                section_separators = "",
            },
            sections = {
                lualine_a = { custom_mode },
                lualine_b = {
                    { gi_component },
                    "branch",
                    "diff",
                    "diagnostic",
                },
                lualine_x = {
                    {
                        encoding_hide_utf8,
                        cond = hide_when_narrow_down,
                    },
                    {
                        ff_hide_linux,
                        cond = hide_when_narrow_down,
                    },
                    {
                        "filetype",
                        cond = hide_when_narrow_down,
                    },
                },
                lualine_y = {
                    { extract_commit_time },
                    {
                        "progress",
                        cond = hide_when_narrow_down,
                    },
                },
            },
            inactive_sections = {
                lualine_b = {
                    { gi_component },
                },
                lualine_x = {
                    { extract_commit_time },
                },
                lualine_y = {
                    "location",
                },
            },
        }
        lualine.setup(config)
    end,
}
