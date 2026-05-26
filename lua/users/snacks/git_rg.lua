local M = {}

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
    local include_types = {}
    local exclude_types = {}
    local include_globs = {}
    local exclude_globs = {}

    local function add_glob(glob, ignore_case)
        glob = strip_quotes(glob)
        local is_exclude = glob:sub(1, 1) == "!"
        if is_exclude then
            glob = glob:sub(2)
        end
        if glob == "" then
            return
        end
        local item = { glob = glob, ignore_case = ignore_case }
        if is_exclude then
            exclude_globs[#exclude_globs + 1] = item
        else
            include_globs[#include_globs + 1] = item
        end
    end

    local i = 1
    while i <= #args do
        local arg = args[i]
        local include_type = arg:match("^%-t=(.+)$") or arg:match("^%-%-type=(.+)$")
        local exclude_type = arg:match("^%-T=(.+)$") or arg:match("^%-%-type%-not=(.+)$")
        local glob = arg:match("^%-g=(.+)$") or arg:match("^%-%-glob=(.+)$")
        local iglob = arg:match("^%-%-iglob=(.+)$")

        if include_type then
            include_types[#include_types + 1] = strip_quotes(include_type)
        elseif exclude_type then
            exclude_types[#exclude_types + 1] = strip_quotes(exclude_type)
        elseif glob then
            add_glob(glob, false)
        elseif iglob then
            add_glob(iglob, true)
        elseif arg == "-t" or arg == "--type" then
            if args[i + 1] then
                include_types[#include_types + 1] = strip_quotes(args[i + 1])
                i = i + 1
            end
        elseif arg == "-T" or arg == "--type-not" then
            if args[i + 1] then
                exclude_types[#exclude_types + 1] = strip_quotes(args[i + 1])
                i = i + 1
            end
        elseif arg == "-g" or arg == "--glob" then
            if args[i + 1] then
                add_glob(args[i + 1], false)
                i = i + 1
            end
        elseif arg == "--iglob" then
            if args[i + 1] then
                add_glob(args[i + 1], true)
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
            include_types = include_types,
            exclude_types = exclude_types,
            include_globs = include_globs,
            exclude_globs = exclude_globs,
            has_rg_args = false,
        }
    end
    return {
        search = text .. " -- " .. table.concat(keep, " "),
        include_types = include_types,
        exclude_types = exclude_types,
        include_globs = include_globs,
        exclude_globs = exclude_globs,
        has_rg_args = true,
    }
end

local function path_matches_glob(path, item)
    local target = item.glob:find("/", 1, true) and path or vim.fs.basename(path)
    local pat = vim.fn.glob2regpat(item.glob)
    if item.ignore_case then
        pat = "\\c" .. pat
    end
    local re = vim.regex(pat)
    return re and re:match_str(target) ~= nil
end

local function file_passes_filters(file, parsed)
    local ext = file:match("%.([%w_+-]+)$")

    if #parsed.include_types > 0 then
        local ok = false
        for _, t in ipairs(parsed.include_types) do
            if t == "all" or (ext and ext == t) then
                ok = true
                break
            end
        end
        if not ok then
            return false
        end
    end

    if #parsed.exclude_types > 0 then
        for _, t in ipairs(parsed.exclude_types) do
            if t == "all" or (ext and ext == t) then
                return false
            end
        end
    end

    if #parsed.include_globs > 0 then
        local ok = false
        for _, item in ipairs(parsed.include_globs) do
            if path_matches_glob(file, item) then
                ok = true
                break
            end
        end
        if not ok then
            return false
        end
    end

    if #parsed.exclude_globs > 0 then
        for _, item in ipairs(parsed.exclude_globs) do
            if path_matches_glob(file, item) then
                return false
            end
        end
    end

    return true
end

local function filter_files(files, parsed)
    local has_filters = #parsed.include_types > 0
        or #parsed.exclude_types > 0
        or #parsed.include_globs > 0
        or #parsed.exclude_globs > 0
    if not has_filters then
        return files
    end

    local filtered = {}
    for _, file in ipairs(files) do
        if file_passes_filters(file, parsed) then
            filtered[#filtered + 1] = file
        end
    end
    return filtered
end

function M.git_rg(opts)
    local snacks = require("snacks")
    local root = get_git_root()
    if not root then
        return snacks.picker.git_grep(opts)
    end

    local files

    local function get_files()
        if files == nil then
            files = get_git_tracked_files(root)
        end
        return files
    end

    return snacks.picker.pick(vim.tbl_deep_extend("force", {
        source = "grep",
        cwd = root,
        finder = function(fopts, ctx)
            local parsed = parse_query_filters(ctx.filter.search)
            local has_base_rg_opts = opts
                and ((opts.args and #opts.args > 0) or opts.ft ~= nil or opts.glob ~= nil or opts.regex == false)
            local has_path_filters = #parsed.include_types > 0
                or #parsed.exclude_types > 0
                or #parsed.include_globs > 0
                or #parsed.exclude_globs > 0

            if not has_path_filters and not parsed.has_rg_args and not has_base_rg_opts then
                local git_finder = require("snacks.picker.source.git").grep
                local search = parsed.search or ""
                local smart_ignorecase = search ~= "" and search == search:lower()
                return git_finder(
                    vim.tbl_deep_extend("force", {
                        cwd = root,
                        need_search = true,
                        untracked = false,
                        submodules = false,
                        ignorecase = smart_ignorecase,
                    }, opts or {}),
                    ctx
                )
            end

            local filtered_files = filter_files(get_files(), parsed)
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

return M
