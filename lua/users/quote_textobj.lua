local ts_range = vim.treesitter._range or require("nvim-treesitter-textobjects._range")

local M = {}

local function update_selection(range)
    local start_row, start_col, end_row, end_col = ts_range.unpack4(range)
    local mode = vim.api.nvim_get_mode().mode
    local selection_mode = "v"

    if mode ~= selection_mode then
        selection_mode = vim.api.nvim_replace_termcodes(selection_mode, true, true, true)
        vim.cmd.normal({ selection_mode, bang = true })
    end

    if end_col == 0 then
        end_row = end_row - 1
        end_col = #vim.api.nvim_buf_get_lines(0, end_row, end_row + 1, true)[1] + 1
    end

    local end_col_offset = vim.o.selection == "exclusive" and 0 or 1
    end_col = end_col - end_col_offset

    vim.api.nvim_win_set_cursor(0, { start_row + 1, start_col })
    vim.cmd("normal! o")
    vim.api.nvim_win_set_cursor(0, { end_row + 1, end_col })
end

local function string_inner_range(range)
    local start_row, start_col, end_row, end_col = ts_range.unpack4(range)
    local text = vim.api.nvim_buf_get_text(0, start_row, start_col, end_row, end_col, {})
    if #text == 0 then
        return range
    end

    local first = text[1] or ""
    local last = text[#text] or ""
    local prefix = first:match("^[rRuUbBfF]*") or ""
    local rest = first:sub(#prefix + 1)

    local delim
    if rest:sub(1, 3) == "\"\"\"" or rest:sub(1, 3) == "'''" then
        delim = rest:sub(1, 3)
    elseif rest:sub(1, 1) == "\"" or rest:sub(1, 1) == "'" or rest:sub(1, 1) == "`" then
        delim = rest:sub(1, 1)
    end

    if not delim or last:sub(-#delim) ~= delim then
        return range
    end

    local start_shift = #prefix + #delim
    local end_shift = #delim
    local new_start_col = start_col + start_shift
    local new_end_col = end_col - end_shift

    if start_row == end_row and new_start_col >= new_end_col then
        return range
    end

    return { start_row, new_start_col, end_row, new_end_col }
end

local function pos_lt(ar, ac, br, bc)
    return ar < br or (ar == br and ac < bc)
end

local function pos_le(ar, ac, br, bc)
    return ar < br or (ar == br and ac <= bc)
end

local function range_contains(range, row, col)
    local sr, sc, er, ec = ts_range.unpack4(range)
    return pos_le(sr, sc, row, col) and pos_lt(row, col, er, ec)
end

local function range_metric(range)
    local sr, sc, er, ec = ts_range.unpack4(range)
    return (er - sr) * 1000000 + (ec - sc)
end

local function collect_string_ranges(bufnr)
    local ok_parser, parser = pcall(vim.treesitter.get_parser, bufnr)
    if not ok_parser or not parser then
        return {}
    end

    local lang = parser:lang()
    local trees = parser:parse() or {}
    if type(trees) ~= "table" then
        return {}
    end

    local query = vim.treesitter.query.get(lang, "highlights")
    if not query then
        return {}
    end

    local ranges = {}
    local seen = {}
    for _, tree in ipairs(trees) do
        local root = tree:root()
        for id, node in query:iter_captures(root, bufnr, 0, -1) do
            if query.captures[id] == "string" then
                local sr, sc, er, ec = node:range()
                local key = table.concat({ sr, sc, er, ec }, ":")
                if not seen[key] then
                    seen[key] = true
                    ranges[#ranges + 1] = { sr, sc, er, ec }
                end
            end
        end
    end

    return ranges
end

local function nearest_string_range(bufnr)
    local ranges = collect_string_ranges(bufnr)
    if #ranges == 0 then
        return nil
    end

    local cursor = vim.api.nvim_win_get_cursor(0)
    local row = cursor[1] - 1
    local col = cursor[2]

    local best_inside = nil
    local best_inside_len = nil
    local best_ahead = nil
    local best_behind = nil

    for _, range in ipairs(ranges) do
        local sr, sc = range[1], range[2]

        if range_contains(range, row, col) then
            local len = range_metric(range)
            if
                not best_inside
                or len < best_inside_len
                or (len == best_inside_len and pos_lt(sr, sc, best_inside[1], best_inside[2]))
            then
                best_inside = range
                best_inside_len = len
            end
        elseif pos_lt(row, col, sr, sc) then
            if
                not best_ahead
                or pos_lt(sr, sc, best_ahead[1], best_ahead[2])
                or (sr == best_ahead[1] and sc == best_ahead[2] and range_metric(range) < range_metric(best_ahead))
            then
                best_ahead = range
            end
        else
            if
                not best_behind
                or pos_lt(best_behind[1], best_behind[2], sr, sc)
                or (sr == best_behind[1] and sc == best_behind[2] and range_metric(range) < range_metric(best_behind))
            then
                best_behind = range
            end
        end
    end

    return best_inside or best_ahead or best_behind
end

function M.select_quote(inner)
    local bufnr = vim.api.nvim_get_current_buf()
    local range = nearest_string_range(bufnr)
    if not range then
        return
    end

    if inner then
        range = string_inner_range(range)
    end

    update_selection(range)
end

function M.setup()
    vim.keymap.set({ "x", "o" }, "aq", function()
        M.select_quote(false)
    end, { desc = "Select quote outer" })
    vim.keymap.set({ "x", "o" }, "iq", function()
        M.select_quote(true)
    end, { desc = "Select quote inner" })
end

return M
