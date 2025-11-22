local dedoc_bufnr = nil
local dedoc_win = nil

local function get_dedoc_buf()
    if not dedoc_bufnr or not vim.api.nvim_buf_is_valid(dedoc_bufnr) then
        dedoc_bufnr = vim.api.nvim_create_buf(false, true)
    end
    return dedoc_bufnr
end

local Snacks = require("snacks")

function removeRedundantSpaces(str)
    -- Replace multiple spaces with a single space
    local cleanedStr = string.gsub(str, "%s+", " ")
    -- Trim leading and trailing spaces
    cleanedStr = string.gsub(cleanedStr, "^%s*(.-)%s*$", "%1")
    return cleanedStr
end

local dedoc = function(opts)
    opts = opts or { lang = "cpp" }

    Snacks.picker({
        title = opts.title or "DeDoc Search",

        formatters = {
            file = {
                filename_first = false,
            },
        },

        finder = function(config, ctx)
            local command = string.format("dedoc ss %s | tail -n +3", opts.lang)
            return require("snacks.picker.source.proc").proc({
                cmd = "sh",
                args = { "-c", command },
                transform = function(item)
                    local line = removeRedundantSpaces(item.text)
                    local ln = vim.split(line, " ")
                    return {
                        text = ln[2],
                        idx = item.idx,
                        file = ln[2],
                    }
                end,
            }, ctx)
        end,

        preview = function(item, ctx)
            local buf = item.picker.preview.win.buf
            local lines = vim.fn.systemlist("dedoc op " .. opts.lang .. " " .. item.item.file)
            vim.bo[buf].modifiable = true
            vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
            vim.bo[buf].filetype = "markdown"
            vim.bo[buf].modifiable = false
        end,

        confirm = function(picker, item)
            picker:close()

            local lines = vim.fn.systemlist("dedoc op " .. opts.lang .. " " .. item.text)
            local bufnr = get_dedoc_buf()
            vim.bo[bufnr].modifiable = true
            vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
            vim.bo[bufnr].filetype = "markdown"
            vim.bo[bufnr].buftype = "nofile"
            vim.bo[bufnr].bufhidden = "hide"
            vim.bo[bufnr].modifiable = false
            vim.api.nvim_buf_set_name(bufnr, "dedoc")

            if dedoc_win and vim.api.nvim_win_is_valid(dedoc_win) then
                vim.api.nvim_win_set_buf(dedoc_win, bufnr)
            else
                vim.cmd("split")
                vim.api.nvim_win_set_buf(0, bufnr)
                dedoc_win = vim.api.nvim_get_current_win()
            end
        end,
    })
end

vim.api.nvim_create_user_command("ToggleDedoc", function()
    if dedoc_win and vim.api.nvim_win_is_valid(dedoc_win) then
        vim.api.nvim_win_close(dedoc_win, false)
    elseif dedoc_bufnr and vim.api.nvim_buf_is_valid(dedoc_bufnr) then
        vim.cmd("split")
        dedoc_win = vim.api.nvim_get_current_win()
        vim.api.nvim_win_set_buf(dedoc_win, dedoc_bufnr)
    end
end, { desc = "Toggle dedoc window" })

vim.api.nvim_create_autocmd("BufEnter", {
    pattern = "dedoc",
    callback = function()
        vim.keymap.set("n", "q", function()
            vim.api.nvim_win_close(dedoc_win, false)
        end)
    end,
})

vim.api.nvim_create_user_command("Cpd", function()
    dedoc({ lang = "cpp", title = "DeDoc C++" })
end, { desc = "DeDoc C++" })

vim.api.nvim_create_user_command("Jsd", function()
    dedoc({ lang = "javascript", title = "DeDoc Javascript" })
end, { desc = "DeDoc Javascript" })

require("shared.utils").keymap("n", "<C-a>", ":ToggleDedoc<CR>", { desc = "Toggle dedoc window" })
