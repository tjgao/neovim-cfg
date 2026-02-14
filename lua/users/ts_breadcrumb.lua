local width = 160
local margin = 1

local function add_inner_left_margin(lines, mgin)
    local padded = {}
    for _, line in ipairs(lines) do
        table.insert(padded, string.rep(" ", mgin) .. line)
    end
    return padded
end

local function breadscrumb_popup(text)
    local lines = type(text) == "string" and add_inner_left_margin(vim.split(text, "\n"), margin) or text
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    local w = width
    if #lines == 1 and #lines[1] < w then
        w = #lines[1]
    end
    local opts = {
        relative = "cursor",
        row = 1,
        col = 0,
        style = "minimal",
        border = "rounded",
        focusable = false,
        noautocmd = true,
        width = w,
        height = #lines,
    }

    local win = vim.api.nvim_open_win(buf, false, opts)
    vim.api.nvim_set_option_value("winhighlight", "Normal:NormalFloat,FloatBorder:FloatBorder", { win = win })

    -- define a cleanup function
    local function close_popup()
        if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_close(win, true)
        end
        if vim.api.nvim_buf_is_valid(buf) then
            vim.api.nvim_buf_delete(buf, { force = true })
        end
    end

    -- automatically close when cursor moves or buffer changes
    vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "BufLeave", "InsertEnter" }, {
        once = true,
        callback = close_popup,
    })

    return win
end

local function split_string(str, size)
    local parts = {}
    for i = 1, #str, size do
        table.insert(parts, str:sub(i, i + size - 1))
    end
    return table.concat(parts, "\n")
end

local ts = require("nvim-treesitter")
local gitsigns = require("gitsigns")

local function line_in_hunk()
    local hunks = gitsigns.get_hunks()
    if not hunks then
        return false
    end

    local current_line = vim.fn.line(".")
    local start_line
    local end_line
    for _, hunk in ipairs(hunks) do
        if hunk.type == "delete" then
            start_line = hunk.removed.start - 1
            if start_line == 0 then
                start_line = 1
            end
            end_line = start_line
        else
            start_line = hunk.added.start
            end_line = hunk.added.start + hunk.added.count - 1
        end
        if current_line >= start_line and current_line <= end_line then
            return true
        end
    end
    return false
end

local function get_treesitter_breadcrumb()
    local bufnr = vim.api.nvim_get_current_buf()
    local cursor = vim.api.nvim_win_get_cursor(0)
    local row = cursor[1] - 1
    local col = cursor[2]

    -- Get parser - new API
    local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
    if not ok or not parser then
        return nil
    end

    -- Parse and get root
    local trees = parser:parse()
    if not trees or #trees == 0 then
        return nil
    end

    local root = trees[1]:root()

    -- Get node at cursor - new API
    local node = root:named_descendant_for_range(row, col, row, col)
    if not node then
        return nil
    end

    -- Build breadcrumb by walking up the tree
    local breadcrumb = {}
    local current = node

    -- More comprehensive list of context nodes
    local function is_context_node(node_type)
        -- Namespace/Module level
        if node_type:match("namespace") or node_type:match("module") or node_type:match("package") then
            return true, "namespace"
        end

        -- Class/Struct/Interface level
        if
            node_type:match("class")
            or node_type:match("struct")
            or node_type:match("interface")
            or node_type:match("trait")
            or node_type:match("impl")
            or node_type:match("object")
            or node_type:match("enum")
        then
            return true, "class"
        end

        -- Function/Method level
        if
            node_type:match("function")
            or node_type:match("method")
            or node_type:match("closure")
            or node_type:match("lambda")
        then
            return true, "function"
        end

        return false, nil
    end

    while current do
        local type = current:type()
        local is_context, context_type = is_context_node(type)

        if is_context then
            local name = ""

            -- Try to find identifier child
            for child in current:iter_children() do
                local child_type = child:type()
                if
                    child_type == "name"
                    or child_type:match("declarator")
                    or child_type:match("identifier")
                    or child_type:match("parameter")
                    or (child_type:match("type") and context_type == "function")
                then
                    local text = vim.trim(vim.treesitter.get_node_text(child, bufnr))
                    if name ~= "" then
                        name = name
                            .. " "
                            .. text:gsub("[\r\n]", ""):gsub("%s+", " "):gsub("%(%s+", "("):gsub("%s+%)", ")")
                    else
                        name = name .. text:gsub("[\r\n]", ""):gsub("%s+", " "):gsub("%(%s+", "("):gsub("%s+%)", ")")
                    end
                    -- name = text:match("^([^%(]+)") or text
                    -- name = name:match("^%s*(.-)%s*$")
                end
            end

            if name and name ~= "" then
                table.insert(breadcrumb, 1, name)
            end
        end

        current = current:parent()
    end

    if #breadcrumb == 0 then
        return nil
    end

    return table.concat(breadcrumb, "   ")
end

require("shared.utils").keymap("n", "KK", function()
    if line_in_hunk() then
        gitsigns.preview_hunk()
    else
        local bread = get_treesitter_breadcrumb()
        if bread ~= nil and bread ~= "" then
            breadscrumb_popup(split_string(bread, width))
        end
    end
end, { desc = "Show treesitter breadcrumb" })
