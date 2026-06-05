local M = {}

local function get_snacks_notifier()
    local ok, notifier = pcall(require, "snacks.notifier")
    if not ok or type(notifier.notify) ~= "function" then
        return nil
    end
    return notifier
end

function M.supports_ids()
    local notifier = get_snacks_notifier()
    return notifier ~= nil and type(notifier.hide) == "function"
end

function M.notify(message, level, opts)
    local notifier = get_snacks_notifier()
    if notifier then
        notifier.notify(message, level, opts)
        return
    end

    vim.notify(message, level)
end

function M.hide(id)
    local notifier = get_snacks_notifier()
    if not notifier or type(notifier.hide) ~= "function" then
        return false
    end

    return pcall(notifier.hide, id)
end

return M
