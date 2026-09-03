local M = {}
local pending = nil
local is_setup = false

local function reopen_cmdline(cmdtype, line, pos)
    vim.schedule(function()
        local lead = cmdtype ~= "" and cmdtype or ":"
        local raw_line = line or ""
        local text = raw_line:gsub("<", "<lt>")
        local safe_pos = math.max(1, math.min(pos or 1, #raw_line + 1))
        local move_left = (#text + 1) - safe_pos
        local tail = move_left > 0 and string.rep("<Left>", move_left) or ""
        local keys = vim.api.nvim_replace_termcodes(lead .. text .. tail, true, false, true)
        vim.api.nvim_feedkeys(keys, "n", false)
    end)
end

local function build_cmdline(cmdline, cmdpos, path)
    local safe_pos = math.max(1, math.min(cmdpos, #cmdline + 1))
    local before = cmdline:sub(1, safe_pos - 1)
    local after = cmdline:sub(safe_pos)

    local insert = vim.fn.fnameescape(path)
    if before ~= "" and not before:match("%s$") then
        insert = " " .. insert
    end
    if after ~= "" and not after:match("^%s") then
        insert = insert .. " "
    end

    local merged = before .. insert .. after
    local new_pos = #before + #insert + 1
    return merged, new_pos
end

function M.pick_and_insert(cmdline, cmdpos, cmdtype)
    local restored = false
    local next_line = cmdline
    local next_pos = cmdpos
    local function restore_once()
        if restored then
            return
        end
        restored = true
        reopen_cmdline(cmdtype, next_line, next_pos)
    end

    local proc = vim.system({ "zoxide", "query", "--list" }, { text = true }):wait()
    if proc.code ~= 0 then
        local err = vim.trim(proc.stderr or "")
        if err == "" then
            err = "zoxide query failed"
        end
        vim.notify(err, vim.log.levels.ERROR)
        restore_once()
        return
    end

    local items = {}
    for path in (proc.stdout or ""):gmatch("[^\r\n]+") do
        if path ~= "" then
            items[#items + 1] = { text = path, file = path, dir = true }
        end
    end

    if #items == 0 then
        vim.notify("No zoxide entries found", vim.log.levels.INFO)
        restore_once()
        return
    end

    require("snacks").picker.pick({
        source = "select",
        format = "file",
        finder = function()
            return items
        end,
        title = "Insert zoxide path",
        focus = "list",
        layout = {
            preset = "vertical",
        },
        confirm = function(picker, item)
            local path = item and (item.file or item.text) or ""
            if path ~= "" then
                next_line, next_pos = build_cmdline(cmdline, cmdpos, path)
            end
            picker:close()
        end,
        on_close = function()
            restore_once()
        end,
    })
end

function M.setup_keymaps()
    if is_setup then
        return
    end
    is_setup = true

    local group = vim.api.nvim_create_augroup("cmdline-zoxide-insert", { clear = true })
    local function trigger()
        pending = {
            cmdline = vim.fn.getcmdline(),
            cmdpos = vim.fn.getcmdpos(),
            cmdtype = vim.fn.getcmdtype(),
        }
        return "<C-c>"
    end

    vim.api.nvim_create_autocmd("CmdlineLeave", {
        group = group,
        callback = function()
            local current = pending
            pending = nil
            if not current then
                return
            end
            vim.schedule(function()
                M.pick_and_insert(current.cmdline, current.cmdpos, current.cmdtype)
            end)
        end,
    })

    vim.keymap.set("c", "<C-x><C-z>", trigger, {
        expr = true,
        noremap = true,
        silent = true,
        desc = "Insert zoxide path in command line",
    })
end

return M
