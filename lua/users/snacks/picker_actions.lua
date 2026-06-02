local M = {}

local function notify_action(level, action, message)
    vim.notify(("Snacks %s: %s"):format(action, message), level)
end

local function get_item_path(item, action)
    if type(item) ~= "table" or type(item.file) ~= "string" or item.file == "" then
        notify_action(vim.log.levels.WARN, action, "selected item has no valid file path")
        return nil
    end
    return item.file
end

function M.get_path(picker, item)
    local path = get_item_path(item, "get path")
    if not path then
        return
    end
    picker:close()
    local home = vim.api.nvim_replace_termcodes("<Home>", true, false, true)
    vim.api.nvim_feedkeys(":" .. vim.fn.fnameescape(path) .. home, "n", false)
end

function M.copy_path(picker, item)
    local path = get_item_path(item, "copy path")
    if not path then
        return
    end
    picker:close()
    local ok = pcall(function()
        vim.fn.setreg('"', path)
        vim.fn.setreg("0", path)
        vim.fn.setreg("+", path)
    end)
    if not ok then
        notify_action(vim.log.levels.ERROR, "copy path", "failed to write registers")
    end
end

function M.copy_filename(picker, item)
    local path = get_item_path(item, "copy filename")
    if not path then
        return
    end
    picker:close()
    local filename = vim.fs.basename(path)
    local ok = pcall(function()
        vim.fn.setreg('"', filename)
        vim.fn.setreg("0", filename)
        vim.fn.setreg("+", filename)
    end)
    if not ok then
        notify_action(vim.log.levels.ERROR, "copy filename", "failed to write registers")
    end
end

function M.open_in_tab(picker, item)
    local path = get_item_path(item, "open in tab")
    if not path then
        return
    end
    picker:close()
    local ok = pcall(vim.cmd, "tabedit " .. vim.fn.fnameescape(path))
    if not ok then
        notify_action(vim.log.levels.ERROR, "open in tab", "failed to open file")
    end
end

return M
