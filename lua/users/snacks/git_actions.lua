local M = {}
local notify = require("shared.notify")
local SPINNER_FRAMES = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }

local function notify_progress_start(message)
    if not notify.supports_ids() then
        notify.notify(message, vim.log.levels.INFO, { title = "Git" })
        return function() end
    end

    local notif_id = ("git-branch-sync-%d"):format(vim.uv.hrtime())
    local frame_index = 0
    local active = true

    local uv = vim.uv or vim.loop
    local timer = uv.new_timer()
    if timer then
        timer:start(
            120,
            120,
            vim.schedule_wrap(function()
                if not active then
                    return
                end
                frame_index = (frame_index % #SPINNER_FRAMES) + 1
                notify.notify(("%s %s"):format(SPINNER_FRAMES[frame_index], message), vim.log.levels.INFO, {
                    id = notif_id,
                    title = "Git",
                    timeout = false,
                })
            end)
        )
    end

    return function()
        active = false
        if timer then
            timer:stop()
            timer:close()
            timer = nil
        end
        vim.defer_fn(function()
            notify.hide(notif_id)
        end, 200)
    end
end

local function run_git_async(args, cwd, cb)
    vim.system(args, {
        cwd = cwd,
        text = true,
    }, function(proc)
        if proc.code ~= 0 then
            local err = vim.trim(proc.stderr or "")
            if err == "" then
                err = vim.trim(proc.stdout or "")
            end
            cb(nil, err ~= "" and err or "git command failed")
            return
        end
        cb(proc, nil)
    end)
end

local function resolve_upstream_async(cwd, local_branch, cb)
    run_git_async(
        {
            "git",
            "for-each-ref",
            "--format=%(upstream:short)",
            "refs/heads/" .. local_branch,
        },
        cwd,
        function(proc, err)
            if not proc then
                cb(nil, nil, err)
                return
            end

            local upstream = vim.trim(proc.stdout or "")
            if upstream == "" then
                cb(nil, nil, nil)
                return
            end

            local remote, remote_branch = upstream:match("^([^/]+)/(.+)$")
            if not remote or not remote_branch then
                cb(nil, nil, nil)
                return
            end
            cb(remote, remote_branch, nil)
        end
    )
end

function M.diffview_d(picker, item)
    vim.cmd(("DiffviewOpen %s^!"):format(item.commit))
    picker:close()
end

function M.diffview_D(picker, item)
    vim.cmd(("DiffviewOpen %s"):format(item.commit))
    picker:close()
end

function M.diffview_x(picker, item)
    picker:close()
    local fname = vim.api.nvim_buf_get_name(0)
    vim.cmd(("DiffviewOpen %s HEAD -- %s"):format(item.commit, fname))
end

function M.commit_to_cmd(picker, item)
    picker:close()
    local home = vim.api.nvim_replace_termcodes("<Home>", true, false, true)
    vim.api.nvim_feedkeys(":" .. item.commit .. home, "n", false)
end

function M.branch_to_cmd(picker, item)
    local branch = type(item) == "table" and item.branch or nil
    if type(branch) ~= "string" or branch == "" then
        notify.notify("No branch name found", vim.log.levels.WARN, { title = "Git" })
        return
    end

    picker:close()
    local home = vim.api.nvim_replace_termcodes("<Home>", true, false, true)
    vim.api.nvim_feedkeys(":" .. branch .. home, "n", false)
end

function M.commit_to_reg(picker, item)
    picker:close()
    vim.fn.setreg('"', item.commit)
    vim.fn.setreg("0", item.commit)
    vim.fn.setreg("+", item.commit)
end

function M.branch_to_reg(picker, item)
    local branch = type(item) == "table" and item.branch or nil
    if type(branch) ~= "string" or branch == "" then
        notify.notify("No branch name found", vim.log.levels.WARN, { title = "Git" })
        return
    end

    picker:close()
    vim.fn.setreg('"', branch)
    vim.fn.setreg("0", branch)
    vim.fn.setreg("+", branch)
end

function M.sync_local_branch(item, opts, on_done)
    opts = opts or {}
    on_done = on_done or function() end
    local force = opts.force == true

    local branch = type(item) == "table" and item.branch or nil
    if type(branch) ~= "string" or branch == "" then
        notify.notify("No branch selected", vim.log.levels.WARN, { title = "Git" })
        on_done(false)
        return false
    end

    local is_remote = branch:match("^remotes/[^/]+/.+") ~= nil
    if is_remote then
        notify.notify(("Skip remote branch '%s'"):format(branch), vim.log.levels.INFO, { title = "Git" })
        on_done(false)
        return false
    end

    local cwd = type(item) == "table" and item.cwd or nil

    resolve_upstream_async(cwd, branch, function(remote, remote_branch, upstream_err)
        local done_progress = function() end
        local function finish(ok)
            done_progress()
            on_done(ok)
        end

        if upstream_err then
            notify.notify(
                ("Failed to resolve upstream for '%s': %s"):format(branch, upstream_err),
                vim.log.levels.ERROR,
                { title = "Git" }
            )
            finish(false)
            return
        end

        if not remote or not remote_branch then
            remote = "origin"
            remote_branch = branch
        end

        done_progress = notify_progress_start(("Syncing '%s' from %s/%s..."):format(branch, remote, remote_branch))
        local refspec = (force and "+" or "") .. remote_branch .. ":" .. branch
        run_git_async({ "git", "fetch", remote, refspec }, cwd, function(_, fetch_err)
            if fetch_err then
                notify.notify(
                    ("Failed to sync '%s' from %s/%s: %s"):format(branch, remote, remote_branch, fetch_err),
                    vim.log.levels.ERROR,
                    { title = "Git" }
                )
                finish(false)
                return
            end

            notify.notify(
                ("Synced local branch '%s' from %s/%s"):format(branch, remote, remote_branch),
                vim.log.levels.INFO,
                { title = "Git" }
            )
            finish(true)
        end)
    end)

    return true
end

function M.sync_and_checkout_local_branch(item, opts, on_done)
    opts = opts or {}
    on_done = on_done or function() end

    local branch = type(item) == "table" and item.branch or nil
    if type(branch) ~= "string" or branch == "" then
        notify.notify("No branch selected", vim.log.levels.WARN, { title = "Git" })
        on_done(false, false)
        return false
    end

    local is_current = type(item) == "table" and item.current == true
    if is_current then
        return M.sync_local_branch(item, opts, function(ok)
            on_done(ok, false)
        end)
    end

    return M.sync_local_branch(item, opts, function(ok)
        if not ok then
            on_done(false, false)
            return
        end

        local cwd = type(item) == "table" and item.cwd or nil
        run_git_async({ "git", "switch", branch }, cwd, function(_, switch_err)
            if switch_err then
                notify.notify(
                    ("Failed to checkout '%s': %s"):format(branch, switch_err),
                    vim.log.levels.ERROR,
                    { title = "Git" }
                )
                on_done(false, false)
                return
            end

            notify.notify(("Checked out '%s'"):format(branch), vim.log.levels.INFO, { title = "Git" })
            on_done(true, true)
        end)
    end)
end

return M
