-- local ts_utils = require("nvim-treesitter.ts_utils")
-- local ts = vim.treesitter
-- local ts = require("nvim-treesitter")

-- local function get_node_text(node, bufnr)
--     local start_row, start_col, end_row, end_col = node:range()
--     local lines = vim.api.nvim_buf_get_lines(bufnr, start_row, end_row + 1, false)
--     if #lines == 0 then
--         return ""
--     end
--     lines[1] = string.sub(lines[1], start_col + 1)
--     lines[#lines] = string.sub(lines[#lines], 1, end_col)
--     return table.concat(lines, " ")
-- end
--
-- local breadcrumb_nodes = {
--     { "function", "" },
--     { "function_definition", "" },
--     { "generator_function_declaration", "" },
--     { "method_declaration", "" },
--     { "method_definition", "" },
--     { "enum_specifier", "" },
--     { "structure_specifier", "" },
--     { "structure_declaration", "" },
--     { "class_specifier", "" },
--     { "class_definition", "" },
--     { "class_declaration", "" },
--     { "struct_specifier", "" },
--     { "namespace_definition", "" },
--     { "interface_declaration", "" },
-- }
--
-- local function check_breadcrumb_node(node)
--     for _, kind in ipairs(breadcrumb_nodes) do
--         if node:type() == kind[1] then
--             return kind
--         end
--     end
--     return nil
-- end
--
-- local function get_clean_node_name(node, buf)
--     if not node then
--         return ""
--     end
--     buf = buf or 0
--
--     -- Preferred: look for name/identifier fields
--     for _, field_name in ipairs({ "name", "identifier", "declarator" }) do
--         local field = node:field(field_name)[1]
--         if field then
--             return vim.trim(ts.get_node_text(field, buf))
--         end
--     end
--
--     local t = node:type()
--
--     -- Special handling for C/C++ functions
--     if t == "function_definition" or t == "function_declarator" then
--         -- Find the identifier child of the declarator
--         for child in node:iter_children() do
--             local ctype = child:type()
--             if ctype:find("declarator") or ctype == "identifier" then
--                 return get_clean_node_name(child, buf)
--             end
--         end
--     end
--
--     -- If this node *is* the identifier, just return it
--     if t == "identifier" or t == "field_identifier" then
--         return vim.trim(ts.get_node_text(node, buf))
--     end
--
--     -- Strip text before '(' if all else fails
--     local text = ts.get_node_text(node, buf) or ""
--     text = text:match("^([^%(%s]+)") or text
--     text = vim.trim(text)
--
--     return text
-- end
--
-- local function get_breadcrumb()
--     local node = ts_utils.get_node_at_cursor()
--     local bufnr = vim.api.nvim_get_current_buf()
--     local breadcrumb = {}
--
--     while node do
--         local symbol = check_breadcrumb_node(node)
--         if symbol ~= nil then
--             local text = get_clean_node_name(node, bufnr)
--             -- Optional: clean up long lines
--             text = text:gsub("%s+", " ")
--             text = symbol[2] .. " " .. vim.trim(text)
--             table.insert(breadcrumb, 1, text)
--         end
--         node = node:parent()
--     end
--
--     return table.concat(breadcrumb, " > ")
-- end

--------

local width = 100
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

    local opts = {
        relative = "cursor",
        row = 1,
        col = 0,
        style = "minimal",
        border = "rounded",
        focusable = false,
        noautocmd = true,
        width = width + margin * 2,
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

local opts = {
    indicator_size = 10000,
    type_patterns = { "namespace", "class", "struct", "function", "method", "interface" },
    ---@diagnostic disable-next-line: unused-local
    transform_fn = function(line, _node)
        return line:gsub("%s*[%[%(%{]*%s*$", "")
    end,
    separator = " → ",
    allow_duplicates = false,
}

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

local capture_types = {
    -- Functions/Methods
    "function_declaration",
    "function_definition",
    "method_declaration",
    "method_definition",
    "function_item", -- Rust
    "arrow_function",
    "function_expression",
    "method",
    "function",
    "lambda",
    "closure_expression",

    -- Classes/Structs/Objects
    "class_declaration",
    "class_definition",
    "struct_item", -- Rust
    "struct_specifier", -- C/C++
    "union_specifier", -- C/C++
    "impl_item", -- Rust
    "trait_item", -- Rust
    "interface_declaration",
    "type_declaration",
    "class_specifier", -- C++
    "object_definition", -- Scala
    "enum_declaration",
    "enum_item", -- Rust

    -- Namespaces/Modules/Packages
    "namespace_definition",
    "namespace_declaration", -- C++/C#
    "module",
    "mod_item", -- Rust
    "package_declaration",
    "package_clause", -- Go
    "module_definition", -- Python (if using module-level structure)

    -- Language-specific
    "for_statement", -- Sometimes useful for context
    "if_statement", -- Sometimes useful
}

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
        -- vim.print(type .. ": " .. vim.treesitter.get_node_text(current, bufnr))
        local is_context, context_type = is_context_node(type)

        if is_context then
            local name = nil

            -- Try to find identifier child
            for child in current:iter_children() do
                local child_type = child:type()
                if
                    child_type:match("function")
                    or child_type:match("method")
                    or child_type:match("class")
                    or child_type:match("structure")
                    or child_type:match("namespace")
                    -- child_type == "function"
                    -- or child_type == "name"
                    -- or child_type == "function_declarator"
                    -- or child_type == "function_definition"
                    -- or child_type == "generator_function_declaration"
                    -- or child_type == "structure_specifier"
                    -- or child_type == "structure_definition"
                    -- or child_type == "structure_declaration"
                    -- or child_type == "class_specifier"
                    -- or child_type == "class_definintion"
                    -- or child_type == "class_declaration"
                    -- or child_type == "namespace"
                    -- or child_type == "namespace_identifier"
                    -- or child_type == "interface_declaration"
                then
                    local text = vim.treesitter.get_node_text(child, bufnr)
                    name = string.gsub(text, "[\r\n]", "")
                    name = string.gsub(name, "%s+", " ")
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

    return table.concat(breadcrumb, " -> ")
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
