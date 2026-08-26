local M = {}

local function default_entry_key(entry)
    return table.concat({
        tostring(entry.bufnr or ""),
        tostring(entry.lnum or ""),
        tostring(entry.col or ""),
        tostring(entry.end_lnum or ""),
        tostring(entry.end_col or ""),
        tostring(entry.type or ""),
        tostring(entry.nr or ""),
        tostring(entry.pattern or ""),
        tostring(entry.text or ""),
    }, "\31")
end

local function refresh_picker(picker)
    if not picker or picker.closed or type(picker.find) ~= "function" then
        return
    end
    if picker.list and type(picker.list.set_target) == "function" then
        picker.list:set_target()
    end
    picker:find()
end

local function selected_entries(picker, item, extract_entry, entry_key)
    local ret = {}
    local seen = {}

    local function add_picker_item(it)
        if type(it) ~= "table" then
            return
        end
        local entry = extract_entry(it)
        if type(entry) ~= "table" then
            return
        end
        local key = entry_key(entry)
        if seen[key] then
            return
        end
        seen[key] = true
        ret[#ret + 1] = entry
    end

    local mode = vim.fn.mode()
    local is_visual = mode == "v" or mode == "V" or mode == "\22"
    if
        is_visual
        and picker
        and picker.list
        and type(picker.list.get) == "function"
        and type(picker.list.row2idx) == "function"
    then
        local list_buf = picker.list.win and picker.list.win.buf or nil
        if list_buf and vim.api.nvim_get_current_buf() == list_buf then
            local vstart = vim.fn.getpos("v")
            local cursor = vim.api.nvim_win_get_cursor(0)
            local first = math.min(vstart[2], cursor[1])
            local last = math.max(vstart[2], cursor[1])
            for row = first, last do
                add_picker_item(picker.list:get(picker.list:row2idx(row)))
            end
        end
    end

    if #ret > 0 then
        return ret
    end

    local selected = {}
    if picker and type(picker.selected) == "function" then
        selected = picker:selected({ fallback = true })
    end
    if #selected == 0 and item then
        selected = { item }
    end

    for _, it in ipairs(selected) do
        add_picker_item(it)
    end
    return ret
end

---@class users.snacks.list_actions.Opts
---@field list_name string
---@field get_entries fun(picker:any): table, table
---@field set_entries fun(picker:any, entries:table, meta:table): nil
---@field extract_entry? fun(item:table): table|nil
---@field entry_key? fun(entry:table): string

---@param opts users.snacks.list_actions.Opts
---@return { remove_selected: fun(picker:any, item:any), clear_all: fun(picker:any) }
function M.make(opts)
    local list_name = opts.list_name
    local get_entries = opts.get_entries
    local set_entries = opts.set_entries
    local extract_entry = opts.extract_entry or function(it)
        return it.item
    end
    local entry_key = opts.entry_key or default_entry_key

    local function remove_selected(picker, item)
        local selected = selected_entries(picker, item, extract_entry, entry_key)
        if #selected == 0 then
            vim.notify(("No %s item selected"):format(list_name), vim.log.levels.WARN)
            return
        end

        local mode = vim.fn.mode()
        if mode == "v" or mode == "V" or mode == "\22" then
            local esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
            vim.api.nvim_feedkeys(esc, "nx", false)
        end

        local remove = {}
        for _, entry in ipairs(selected) do
            local key = entry_key(entry)
            remove[key] = (remove[key] or 0) + 1
        end

        local items, meta = get_entries(picker)
        local kept = {}
        local removed = 0

        for _, entry in ipairs(items) do
            local key = entry_key(entry)
            local n = remove[key] or 0
            if n > 0 then
                remove[key] = n - 1
                removed = removed + 1
            else
                kept[#kept + 1] = entry
            end
        end

        if removed == 0 then
            vim.notify(("No matching %s items removed"):format(list_name), vim.log.levels.WARN)
            return
        end

        set_entries(picker, kept, meta)
        vim.notify(("Removed %d %s item(s)"):format(removed, list_name), vim.log.levels.INFO)
        refresh_picker(picker)
    end

    local function clear_all(picker)
        local _, meta = get_entries(picker)
        set_entries(picker, {}, meta)
        vim.notify(("Cleared %s list"):format(list_name), vim.log.levels.INFO)
        refresh_picker(picker)
    end

    return {
        remove_selected = remove_selected,
        clear_all = clear_all,
    }
end

return M
