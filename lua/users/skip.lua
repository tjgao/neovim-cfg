-- Some little handy skip functions in insert mode
-- Move forward/backward and stop at some potentially meaningful positions

local stoppers = { ".", ",", ";", "(", ")", "{", "}", "'", "'", '"', '"', "[", "]" }

local function isspace(str)
    return str ~= nil and str:match("%s") ~= nil
end

local function nonspace(str)
    return str ~= nil and str:match("[^%s]") ~= nil
end

local function isstopper(ch)
    for _, v in ipairs(stoppers) do
        if v == ch then
            return true
        end
    end
    return false
end

local function move(str, idx, direction)
    local ch, prev
    if direction then
        idx = idx + 1
        if isstopper(string.sub(str, idx, idx)) then
            idx = idx + 1
        end
        while idx ~= #str + 1 do
            ch = string.sub(str, idx, idx)
            if isstopper(ch) or (nonspace(ch) and isspace(prev)) then
                return idx - 1
            end
            prev = ch
            idx = idx + 1
        end
        return idx - 1
    else
        idx = idx - 1
        if isstopper(string.sub(str, idx, idx)) then
            idx = idx - 1
        end
        while idx >= 0 do
            ch = string.sub(str, idx, idx)
            if isstopper(ch) then
                if isstopper(prev) then
                    return idx + 1
                elseif nonspace(prev) then
                    return idx
                end
                return idx + 1
            elseif nonspace(ch) and isspace(prev) then
                return idx + 1
            end
            prev = ch
            idx = idx - 1
        end
        return math.max(idx, 0)
    end
end

local function move_left()
    local r, c = unpack(vim.api.nvim_win_get_cursor(0))
    local line = vim.api.nvim_get_current_line()
    if c == 0 then
        if r <= 1 then
            return
        end
        r = r - 1
        line = vim.api.nvim_buf_get_lines(0, r - 1, r, true)[1]
        c = #line + 1
    end
    local pos = move(line, c, false)
    vim.api.nvim_win_set_cursor(0, { r, pos })
end

local function move_right()
    local r, c = unpack(vim.api.nvim_win_get_cursor(0))
    local line = vim.api.nvim_get_current_line()
    if c == #line then
        local line_count = vim.api.nvim_buf_line_count(0)
        if line_count == r then
            return
        end
        r = r + 1
        c = -1
        line = vim.api.nvim_buf_get_lines(0, r - 1, r, true)[1]
    end
    local pos = move(line, c, true)
    vim.api.nvim_win_set_cursor(0, { r, pos })
end

-- I am a "good" fox jumping around

local function skip_to_end()
    local r, _ = unpack(vim.api.nvim_win_get_cursor(0))
    local line = vim.api.nvim_get_current_line()
    vim.api.nvim_win_set_cursor(0, { r, #line })
    return true
end

local function skip_to_beginning()
    local r, _ = unpack(vim.api.nvim_win_get_cursor(0))
    local line = vim.api.nvim_get_current_line()
    for i = 1, #line, 1 do
        if not isspace(string.sub(line, i, i)) then
            vim.api.nvim_win_set_cursor(0, { r, i - 1 })
            return true
        end
    end
    return false
end

-- insert mode thing, similar to <C-w>
-- delete the right part
vim.keymap.set("i", "<C-q>", "<C-o>dw", { desc = "Delete right part" })

vim.keymap.set("i", "<C-j>", "<Down>", { desc = "Move up" })
vim.keymap.set("i", "<C-k>", "<Up>", { desc = "Move down" })

vim.keymap.set("i", "<C-e>", skip_to_end, { desc = "Skip to the end" })
vim.keymap.set("i", "<C-a>", skip_to_beginning, { desc = "Skip to the beginning" })

vim.keymap.set("i", "<C-l>", move_right, { desc = "Skip out of pairs -> right" })
vim.keymap.set("i", "<C-h>", move_left, { desc = "Skip out of pairs -> left" })
