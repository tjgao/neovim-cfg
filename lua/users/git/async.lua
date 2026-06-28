local M = {}

local SPINNER_FRAMES = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }

local function get_fy_notifier()
    local ok, notifier = pcall(require, "fy")
    if not ok or type(notifier.notify) ~= "function" then
        return nil
    end
    return notifier
end

local function get_snacks_notifier()
    local ok, notifier = pcall(require, "snacks.notifier")
    if not ok or type(notifier.notify) ~= "function" or type(notifier.hide) ~= "function" then
        return nil
    end
    return notifier
end

local function close_fy_handle(handle)
    if not handle then
        return
    end
    if type(handle.close) == "function" then
        pcall(handle.close, handle)
        return
    end
    if type(handle.hide) == "function" then
        pcall(handle.hide, handle)
        return
    end
    if type(handle.dismiss) == "function" then
        pcall(handle.dismiss, handle)
    end
end

function M.start_spinner_fy(message, opts)
    opts = opts or {}
    local title = opts.title or "Git"
    local notifier = get_fy_notifier()
    if not notifier then
        return nil
    end

    local frame_index = 1
    local active = true
    local handle = notifier.notify(("%s %s"):format(SPINNER_FRAMES[frame_index], message), vim.log.levels.INFO, {
        title = title,
        timeout = false,
        hide_from_history = true,
    })

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
                handle = notifier.notify(("%s %s"):format(SPINNER_FRAMES[frame_index], message), vim.log.levels.INFO, {
                    title = title,
                    timeout = false,
                    replace = handle,
                    hide_from_history = true,
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
            close_fy_handle(handle)
        end, 200)
    end
end

function M.start_spinner_snacks(message, opts)
    opts = opts or {}
    local title = opts.title or "Git"
    local id_prefix = opts.id_prefix or "git-op"
    local notifier = get_snacks_notifier()
    if not notifier then
        return nil
    end

    local uv = vim.uv or vim.loop
    local notif_id = ("%s-%d"):format(id_prefix, uv.hrtime())
    local frame_index = 1
    local active = true

    notifier.notify(("%s %s"):format(SPINNER_FRAMES[frame_index], message), vim.log.levels.INFO, {
        id = notif_id,
        title = title,
        timeout = false,
    })

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
                notifier.notify(("%s %s"):format(SPINNER_FRAMES[frame_index], message), vim.log.levels.INFO, {
                    id = notif_id,
                    title = title,
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
            pcall(notifier.hide, notif_id)
        end, 200)
    end
end

function M.start_spinner(message, opts)
    local stop = M.start_spinner_fy(message, opts)
    if stop then
        return stop
    end

    stop = M.start_spinner_snacks(message, opts)
    if stop then
        return stop
    end

    vim.notify(message, vim.log.levels.INFO)
    return function() end
end

function M.run(args, cwd, cb)
    vim.system(args, {
        cwd = cwd,
        text = true,
    }, function(proc)
        vim.schedule(function()
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
    end)
end

function M.resolve_git_root(cwd)
    local base = cwd or vim.fn.getcwd()
    local proc = vim.system({ "git", "-C", base, "rev-parse", "--show-toplevel" }, { text = true }):wait()
    if proc.code ~= 0 then
        return nil
    end

    local root = vim.trim(proc.stdout or "")
    if root == "" then
        return nil
    end
    return root
end

return M
