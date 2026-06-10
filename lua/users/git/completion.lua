local git_async = require("users.git.async")

local M = {}

local CACHE = {}
local CACHE_TTL_MS = 1500

local FLAGS = {
    checkout = { "-b", "-B", "--detach", "--track", "--force", "--orphan", "--ours", "--theirs" },
    fetch = { "--all", "--prune", "--tags", "--prune-tags", "--force", "--depth=" },
    pull = { "--ff-only", "--rebase", "--no-rebase", "--autostash", "--no-autostash", "--tags" },
    push = { "-u", "--set-upstream", "--force-with-lease", "--force", "--tags", "--dry-run" },
    commit = { "-m", "--amend", "--no-edit", "--no-verify", "--fixup=", "--squash=" },
}

local function now_ms()
    local uv = vim.uv or vim.loop
    if uv and type(uv.now) == "function" then
        return uv.now()
    end
    return vim.fn.localtime() * 1000
end

local function get_cached(key, producer)
    local now = now_ms()
    local entry = CACHE[key]
    if entry and now - entry.stamp <= CACHE_TTL_MS then
        return entry.value
    end

    local value = producer()
    CACHE[key] = { stamp = now, value = value }
    return value
end

local function parse_lines(text)
    return vim.split(text or "", "\n", { trimempty = true })
end

local function git_lines(root, args)
    local cmd = { "git" }
    vim.list_extend(cmd, args)
    local proc = vim.system(cmd, { cwd = root, text = true }):wait()
    if proc.code ~= 0 then
        return {}
    end
    return parse_lines(proc.stdout)
end

local function get_root()
    return git_async.resolve_git_root(vim.fn.getcwd())
end

local function dedupe(values)
    local seen = {}
    local ret = {}
    for _, v in ipairs(values) do
        if type(v) == "string" and v ~= "" and not seen[v] then
            seen[v] = true
            ret[#ret + 1] = v
        end
    end
    return ret
end

local function copy_list(values)
    local ret = {}
    for _, v in ipairs(values or {}) do
        ret[#ret + 1] = v
    end
    return ret
end

local function concat_lists(...)
    local ret = {}
    for _, values in ipairs({ ... }) do
        if type(values) == "table" then
            for _, v in ipairs(values) do
                ret[#ret + 1] = v
            end
        end
    end
    return ret
end

local function to_set(values)
    local set = {}
    for _, v in ipairs(values or {}) do
        set[v] = true
    end
    return set
end

local function filter_prefix(values, arg_lead)
    if arg_lead == "" then
        return values
    end

    local ret = {}
    for _, v in ipairs(values) do
        if vim.startswith(v, arg_lead) then
            ret[#ret + 1] = v
        end
    end
    return ret
end

local function sort_values(values, rank_fn)
    local ret = copy_list(values)
    table.sort(ret, function(a, b)
        local ra = rank_fn and rank_fn(a) or 0
        local rb = rank_fn and rank_fn(b) or 0
        if ra ~= rb then
            return ra < rb
        end
        return a < b
    end)
    return ret
end

local function previous_args(cmd_line, arg_lead)
    local parts = vim.split(vim.trim(cmd_line), "%s+", { trimempty = true })
    if #parts == 0 then
        return {}
    end

    table.remove(parts, 1)
    if arg_lead ~= "" and #parts > 0 then
        table.remove(parts, #parts)
    end
    return parts
end

local function positional_count(args)
    local count = 0
    for _, arg in ipairs(args) do
        if not vim.startswith(arg, "-") then
            count = count + 1
        end
    end
    return count
end

local function first_positional(args)
    for _, arg in ipairs(args) do
        if not vim.startswith(arg, "-") then
            return arg
        end
    end
    return nil
end

local function remote_names(root)
    return get_cached(root .. ":remote_names", function()
        return git_lines(root, { "remote" })
    end)
end

local function local_branches(root)
    return get_cached(root .. ":local_branches", function()
        return git_lines(root, { "for-each-ref", "--format=%(refname:short)", "refs/heads" })
    end)
end

local function remote_branches(root)
    return get_cached(root .. ":remote_branches", function()
        local branches = git_lines(root, { "for-each-ref", "--format=%(refname:short)", "refs/remotes" })
        local ret = {}
        for _, b in ipairs(branches) do
            if not b:match("/HEAD$") then
                ret[#ret + 1] = b
            end
        end
        return ret
    end)
end

local function tags(root)
    return get_cached(root .. ":tags", function()
        return git_lines(root, { "tag", "--list" })
    end)
end

local function current_branch(root)
    return get_cached(root .. ":current_branch", function()
        local lines = git_lines(root, { "branch", "--show-current" })
        return lines[1] or ""
    end)
end

local function default_remote(root)
    return get_cached(root .. ":default_remote", function()
        local remotes = remote_names(root)
        if vim.tbl_contains(remotes, "origin") then
            return "origin"
        end
        return remotes[1] or ""
    end)
end

local function refs_for_checkout(root)
    return dedupe(concat_lists(local_branches(root), remote_branches(root), tags(root)))
end

local function complete_with(values, arg_lead)
    return filter_prefix(dedupe(values), arg_lead)
end

function M.complete_checkout(arg_lead)
    local root = get_root()
    if not root then
        return complete_with(FLAGS.checkout, arg_lead)
    end

    if vim.startswith(arg_lead, "-") then
        return complete_with(FLAGS.checkout, arg_lead)
    end

    local cur = current_branch(root)
    local locals = local_branches(root)
    local remotes = remote_branches(root)
    local local_set = to_set(locals)
    local remote_set = to_set(remotes)
    local values = sort_values(refs_for_checkout(root), function(v)
        if cur ~= "" and v == cur then
            return 0
        end
        if local_set[v] then
            return 1
        end
        if remote_set[v] then
            return 2
        end
        return 3
    end)
    return complete_with(concat_lists(values, FLAGS.checkout), arg_lead)
end

function M.complete_fetch(arg_lead, cmd_line)
    local root = get_root()
    local args = previous_args(cmd_line, arg_lead)
    local pos_count = positional_count(args)
    if not root then
        return complete_with(FLAGS.fetch, arg_lead)
    end

    if vim.startswith(arg_lead, "-") then
        return complete_with(FLAGS.fetch, arg_lead)
    end

    local preferred_remote = default_remote(root)
    if pos_count == 0 then
        local remotes = sort_values(remote_names(root), function(v)
            if preferred_remote ~= "" and v == preferred_remote then
                return 0
            end
            return 1
        end)
        return complete_with(concat_lists(remotes, FLAGS.fetch), arg_lead)
    end

    local selected_remote = first_positional(args)
    local values = sort_values(concat_lists(remote_branches(root), tags(root)), function(v)
        if selected_remote and selected_remote ~= "" and vim.startswith(v, selected_remote .. "/") then
            return 0
        end
        if preferred_remote ~= "" and vim.startswith(v, preferred_remote .. "/") then
            return 1
        end
        if vim.startswith(v, "refs/") then
            return 3
        end
        return 2
    end)
    return complete_with(values, arg_lead)
end

function M.complete_pull(arg_lead, cmd_line)
    local root = get_root()
    local args = previous_args(cmd_line, arg_lead)
    local pos_count = positional_count(args)
    if not root then
        return complete_with(FLAGS.pull, arg_lead)
    end

    if vim.startswith(arg_lead, "-") then
        return complete_with(FLAGS.pull, arg_lead)
    end

    local preferred_remote = default_remote(root)
    if pos_count == 0 then
        local remotes = sort_values(remote_names(root), function(v)
            if preferred_remote ~= "" and v == preferred_remote then
                return 0
            end
            return 1
        end)
        return complete_with(concat_lists(remotes, FLAGS.pull), arg_lead)
    end

    local cur = current_branch(root)
    local locals = local_branches(root)
    local local_set = to_set(locals)
    local values = sort_values(concat_lists(locals, remote_branches(root)), function(v)
        if cur ~= "" and v == cur then
            return 0
        end
        if local_set[v] then
            return 1
        end
        return 2
    end)
    return complete_with(values, arg_lead)
end

function M.complete_push(arg_lead, cmd_line)
    local root = get_root()
    local args = previous_args(cmd_line, arg_lead)
    local pos_count = positional_count(args)
    if not root then
        return complete_with(FLAGS.push, arg_lead)
    end

    if vim.startswith(arg_lead, "-") then
        return complete_with(FLAGS.push, arg_lead)
    end

    local preferred_remote = default_remote(root)
    if pos_count == 0 then
        local remotes = sort_values(remote_names(root), function(v)
            if preferred_remote ~= "" and v == preferred_remote then
                return 0
            end
            return 1
        end)
        return complete_with(concat_lists(remotes, FLAGS.push), arg_lead)
    end

    local cur = current_branch(root)
    local branches = sort_values(local_branches(root), function(v)
        if cur ~= "" and v == cur then
            return 0
        end
        return 1
    end)
    return complete_with(concat_lists(branches, FLAGS.push), arg_lead)
end

function M.complete_commit(arg_lead)
    return complete_with(FLAGS.commit, arg_lead)
end

return M
