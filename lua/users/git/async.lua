local notify = require("shared.notify")

local M = {}

local SPINNER_FRAMES = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }

function M.start_spinner(message, opts)
    opts = opts or {}
    local title = opts.title or "Git"
    local id_prefix = opts.id_prefix or "git-op"

    if not notify.supports_ids() then
        notify.notify(message, vim.log.levels.INFO, { title = title })
        return function() end
    end

    local uv = vim.uv or vim.loop
    local notif_id = ("%s-%d"):format(id_prefix, uv.hrtime())
    local frame_index = 1
    local active = true

    notify.notify(("%s %s"):format(SPINNER_FRAMES[frame_index], message), vim.log.levels.INFO, {
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
                notify.notify(("%s %s"):format(SPINNER_FRAMES[frame_index], message), vim.log.levels.INFO, {
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
            notify.hide(notif_id)
        end, 200)
    end
end

function M.run(args, cwd, cb)
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
