local M = {}

local STATE = {
    disabled_breakpoints = {},
}

local function breakpoint_key(bufnr, line)
    return tostring(bufnr) .. ":" .. tostring(line)
end

local function save_disabled_breakpoint(bp)
    local bufnr = bp.buf or bp.bufnr
    local line = bp.line
    if type(bufnr) ~= "number" or type(line) ~= "number" then
        return
    end

    local key = breakpoint_key(bufnr, line)
    STATE.disabled_breakpoints[key] = {
        buf = bufnr,
        line = line,
        condition = bp.condition,
        hitCondition = bp.hitCondition,
        logMessage = bp.logMessage,
    }
end

local function remove_disabled_breakpoint(bufnr, line)
    STATE.disabled_breakpoints[breakpoint_key(bufnr, line)] = nil
end

local function clear_disabled_breakpoints()
    STATE.disabled_breakpoints = {}
end

local function lua_string_literal(value)
    if type(value) ~= "string" then
        return '""'
    end
    return string.format("%q", value)
end

local function breakpoint_editor_lines(target)
    return {
        "{",
        '    -- condition = "arr[i] > 10"',
        "    condition = " .. lua_string_literal(target.condition or "") .. ",",
        '    -- hitCondition = "99"',
        "    hitCondition = " .. lua_string_literal(target.hitCondition or "") .. ",",
        '    -- logMessage = "The value of x: {x}"',
        "    logMessage = " .. lua_string_literal(target.logMessage or "") .. ",",
        "}",
    }
end

local function parse_breakpoint_editor(content)
    local chunk, load_err = load("return " .. content, "breakpoint-editor", "t", {})
    if not chunk then
        return nil, "Invalid Lua object: " .. tostring(load_err)
    end

    local ok, parsed = pcall(chunk)
    if not ok then
        return nil, "Failed to evaluate Lua object: " .. tostring(parsed)
    end

    if type(parsed) ~= "table" then
        return nil, "Lua object must evaluate to a table"
    end

    local allowed = {
        condition = true,
        hitCondition = true,
        logMessage = true,
    }

    for key, value in pairs(parsed) do
        if not allowed[key] then
            return nil, ("Unknown field '%s' (allowed: condition, hitCondition, logMessage)"):format(tostring(key))
        end
        if type(value) ~= "string" then
            return nil, ("Field '%s' must be a string"):format(key)
        end
    end

    local condition = parsed.condition
    local hit_condition = parsed.hitCondition
    local log_message = parsed.logMessage

    if condition == "" then
        condition = nil
    end
    if hit_condition == "" then
        hit_condition = nil
    end
    if log_message == "" then
        log_message = nil
    end

    return {
        condition = condition,
        hit_condition = hit_condition,
        log_message = log_message,
    }
end

local function open_breakpoint_editor(dap, picker, target, on_applied)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(buf, "[breakpoint-editor]")
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, breakpoint_editor_lines(target))

    local width = math.min(math.floor(vim.o.columns * 0.6), 90)
    local height = 10
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)
    local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        style = "minimal",
        border = "single",
        width = width,
        height = height,
        row = row,
        col = col,
        title = " Edit Breakpoint Lua Object ",
        title_pos = "center",
        footer = " q apply  |  Q cancel ",
        footer_pos = "center",
    })

    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].swapfile = false
    vim.bo[buf].filetype = "lua"
    vim.wo[win].wrap = false

    local picker_hidden = false
    if picker and picker.layout and type(picker.layout.hide) == "function" then
        picker_hidden = pcall(function()
            picker.layout:hide()
        end)
    end

    local function close_editor(restore_picker)
        if restore_picker == nil then
            restore_picker = true
        end

        if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_close(win, true)
        end

        if
            restore_picker
            and picker_hidden
            and picker
            and not picker.closed
            and picker.layout
            and type(picker.layout.unhide) == "function"
        then
            pcall(function()
                picker.layout:unhide()
            end)
            vim.schedule(function()
                if picker and not picker.closed and type(picker.focus) == "function" then
                    pcall(function()
                        picker:focus("list")
                    end)
                end
            end)
        end
    end

    local function apply_changes()
        local content = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
        local parsed, parse_err = parse_breakpoint_editor(content)
        if not parsed then
            vim.notify(parse_err or "Invalid breakpoint object", vim.log.levels.ERROR)
            return
        end

        if target.enabled then
            require("dap.breakpoints").set({
                condition = parsed.condition,
                hit_condition = parsed.hit_condition,
                log_message = parsed.log_message,
            }, target.bufnr, target.line)
            remove_disabled_breakpoint(target.bufnr, target.line)

            local session = dap.session()
            if session then
                session:set_breakpoints(require("dap.breakpoints").get())
            end
        else
            save_disabled_breakpoint({
                bufnr = target.bufnr,
                line = target.line,
                condition = parsed.condition,
                hitCondition = parsed.hit_condition,
                logMessage = parsed.log_message,
            })
        end

        close_editor(false)
        if picker and type(picker.close) == "function" then
            pcall(function()
                picker:close()
            end)
        end
        if on_applied then
            on_applied()
        end
    end

    local opts = { buffer = buf, silent = true, nowait = true }
    vim.keymap.set("n", "q", apply_changes, vim.tbl_extend("force", opts, { desc = "Apply breakpoint changes" }))
    vim.keymap.set("n", "Q", function()
        close_editor(true)
    end, vim.tbl_extend("force", opts, { desc = "Cancel breakpoint changes" }))
end

local function collect_breakpoint_items()
    local bps = require("dap.breakpoints")
    local grouped = bps.get()
    local items = {}
    local enabled_keys = {}

    for bufnr, entries in pairs(grouped) do
        local file = vim.api.nvim_buf_get_name(bufnr)
        for _, bp in ipairs(entries) do
            local key = breakpoint_key(bp.buf, bp.line)
            enabled_keys[key] = true
            items[#items + 1] = {
                file = file,
                path_display = file ~= "" and vim.fn.fnamemodify(file, ":~:.") or ("[buf " .. bufnr .. "]"),
                bufnr = bp.buf,
                line = bp.line,
                condition = bp.condition,
                hitCondition = bp.hitCondition,
                logMessage = bp.logMessage,
                enabled = true,
            }
        end
    end

    for key, bp in pairs(STATE.disabled_breakpoints) do
        if not enabled_keys[key] then
            if type(bp.buf) ~= "number" or type(bp.line) ~= "number" then
                goto continue
            end

            local file = vim.api.nvim_buf_get_name(bp.buf)
            items[#items + 1] = {
                file = file,
                path_display = file ~= "" and vim.fn.fnamemodify(file, ":~:.") or ("[buf " .. bp.buf .. "]"),
                bufnr = bp.buf,
                line = bp.line,
                condition = bp.condition,
                hitCondition = bp.hitCondition,
                logMessage = bp.logMessage,
                enabled = false,
            }
        end
        ::continue::
    end

    table.sort(items, function(a, b)
        if a.enabled ~= b.enabled then
            return a.enabled == true
        end

        local af = a.file ~= "" and a.file or ("buf:" .. tostring(a.bufnr))
        local bf = b.file ~= "" and b.file or ("buf:" .. tostring(b.bufnr))
        if af ~= bf then
            return af < bf
        end
        return a.line < b.line
    end)

    return items
end

function M.open_picker(dap)
    local function reopen_picker()
        vim.schedule(function()
            M.open_picker(dap)
        end)
    end

    local items = collect_breakpoint_items()
    if #items == 0 then
        items[1] = {
            text = "No breakpoints",
            is_placeholder = true,
        }
    end

    local Snacks = require("snacks")
    vim.api.nvim_set_hl(0, "DapBreakpointIconEnabled", { default = true, link = "DiagnosticOk" })
    vim.api.nvim_set_hl(0, "DapBreakpointIconDisabled", { default = true, link = "Comment" })
    vim.api.nvim_set_hl(0, "DapBreakpointPath", { default = true, link = "SnacksPickerFile" })
    vim.api.nvim_set_hl(0, "DapBreakpointPathDisabled", { default = true, link = "Comment" })
    vim.api.nvim_set_hl(0, "DapBreakpointLine", { default = true, link = "Number" })
    vim.api.nvim_set_hl(0, "DapBreakpointBadge", { default = true, link = "Identifier" })
    vim.api.nvim_set_hl(0, "DapBreakpointBadgeDisabled", { default = true, link = "Comment" })

    Snacks.picker.pick({
        source = "select",
        title = "Breakpoints (Enter jump, E edit, dd delete, t toggle, da clear all)",
        focus = "list",
        auto_close = false,
        format = function(item)
            if item.is_placeholder then
                return { { item.text } }
            end

            local chunks = {}
            local icon = item.enabled == false and "○" or "●"
            local icon_hl = item.enabled == false and "DapBreakpointIconDisabled" or "DapBreakpointIconEnabled"
            local path_hl = item.enabled == false and "DapBreakpointPathDisabled" or "DapBreakpointPath"
            local badge_hl = item.enabled == false and "DapBreakpointBadgeDisabled" or "DapBreakpointBadge"
            local path_text = item.path_display or "[unknown]"

            chunks[#chunks + 1] = { " " .. icon .. " ", icon_hl }
            chunks[#chunks + 1] = { path_text, path_hl }
            chunks[#chunks + 1] = { ":" .. tostring(item.line or "?"), "DapBreakpointLine" }

            if item.condition and item.condition ~= "" then
                chunks[#chunks + 1] = { "  [cond]", badge_hl }
            end
            if item.hitCondition and item.hitCondition ~= "" then
                chunks[#chunks + 1] = { "  [hit]", badge_hl }
            end
            if item.logMessage and item.logMessage ~= "" then
                chunks[#chunks + 1] = { "  [log]", badge_hl }
            end

            return chunks
        end,
        finder = function()
            return items
        end,
        preview = "none",
        confirm = function(picker, item)
            if not item or item.is_placeholder then
                return
            end

            picker:close()
            if item.file and item.file ~= "" then
                vim.cmd("edit " .. vim.fn.fnameescape(item.file))
            elseif item.bufnr and vim.api.nvim_buf_is_valid(item.bufnr) then
                vim.api.nvim_set_current_buf(item.bufnr)
            end
            pcall(vim.api.nvim_win_set_cursor, 0, { item.line, 0 })
            vim.cmd("normal! zz")
        end,
        actions = {
            edit_breakpoint = function(picker, item)
                local selected = picker:selected({ fallback = true })
                if #selected == 0 and item then
                    selected = { item }
                end

                local target = selected[1]
                if not target or target.is_placeholder or not target.bufnr or not target.line then
                    vim.notify("No breakpoint selected", vim.log.levels.WARN)
                    return
                end
                open_breakpoint_editor(dap, picker, target, reopen_picker)
            end,
            delete_selected_breakpoints = function(picker, item)
                local selected = picker:selected({ fallback = true })
                if #selected == 0 and item then
                    selected = { item }
                end

                local bps = require("dap.breakpoints")
                local removed = 0
                for _, it in ipairs(selected) do
                    if not it.is_placeholder and it.bufnr and it.line then
                        if it.enabled then
                            if bps.remove(it.bufnr, it.line) then
                                removed = removed + 1
                            end
                        end
                        remove_disabled_breakpoint(it.bufnr, it.line)
                    end
                end

                if removed > 0 then
                    local session = dap.session()
                    if session then
                        session:set_breakpoints(require("dap.breakpoints").get())
                    end
                end

                picker:close()
                reopen_picker()
            end,
            toggle_selected_breakpoints = function(picker, item)
                local selected = picker:selected({ fallback = true })
                if #selected == 0 and item then
                    selected = { item }
                end

                local bps = require("dap.breakpoints")
                local changed = false
                for _, it in ipairs(selected) do
                    if not it.is_placeholder and it.bufnr and it.line then
                        if it.enabled then
                            if bps.remove(it.bufnr, it.line) then
                                save_disabled_breakpoint(it)
                                changed = true
                            end
                        else
                            bps.set({
                                condition = it.condition,
                                hit_condition = it.hitCondition,
                                log_message = it.logMessage,
                            }, it.bufnr, it.line)
                            remove_disabled_breakpoint(it.bufnr, it.line)
                            changed = true
                        end
                    end
                end

                if changed then
                    local session = dap.session()
                    if session then
                        session:set_breakpoints(require("dap.breakpoints").get())
                    end
                end

                picker:close()
                reopen_picker()
            end,
            clear_all_breakpoints = function(picker)
                local choice = vim.fn.confirm("Clear all breakpoints?", "&No\n&Yes", 1)
                if choice ~= 2 then
                    return
                end

                require("dap.breakpoints").clear()
                clear_disabled_breakpoints()

                local session = dap.session()
                if session then
                    session:set_breakpoints(require("dap.breakpoints").get())
                end

                picker:close()
                vim.notify("Cleared all breakpoints", vim.log.levels.INFO)
            end,
        },
        win = {
            list = {
                keys = {
                    ["E"] = "edit_breakpoint",
                    ["dd"] = "delete_selected_breakpoints",
                    ["t"] = "toggle_selected_breakpoints",
                    ["da"] = "clear_all_breakpoints",
                },
            },
            input = {
                keys = {
                    ["E"] = "edit_breakpoint",
                    ["dd"] = "delete_selected_breakpoints",
                    ["t"] = "toggle_selected_breakpoints",
                    ["da"] = "clear_all_breakpoints",
                },
            },
        },
    })
end

return M
