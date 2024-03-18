-- This lua file provides a command, :Bd or :Bd!
-- It closes all buffers except the current one we are working on
-- If executed with bang (!), the other unsaved buffers will be closed
-- as well. Nvim-tree and terminal buffers are untouched, because that's
-- my preference, I'd like to have them around.
--
-- Close all buffers except current and harpoon bufs (if excluded)

vim.g.bd_exclude_harpoon = true

local function delete_buf(cwd, items, buf, opts)
    if vim.g.bd_exclude_harpoon then
        for _, v in ipairs(items) do
            if cwd .. "/" .. v.value == vim.fn.expand("#" .. buf .. ":p") then
                return
            end
        end
    end
    vim.api.nvim_buf_delete(buf, { force = opts.bang })
end

local function close_allbuf_except_current(opts)
    local cur = vim.api.nvim_win_get_buf(0)
    local status, harpoon = pcall(require, "harpoon")
    local items = (status and harpoon:list().items) or {}
    local cwd = vim.fn.getcwd()
    for _, o in pairs(vim.api.nvim_list_bufs()) do
        if not opts.bang and vim.fn.getbufinfo(o)[1].changed == 1 then
            goto continue
        end
        -- We want to exclude nvim-tree and terminals
        local bt = vim.api.nvim_get_option_value("buftype", { buf = o })
        local ft = vim.api.nvim_get_option_value("filetype", { buf = o })
        if o ~= cur and bt ~= "terminal" and ft ~= "NvimTree" then
            delete_buf(cwd, items, o, opts)
        end
        ::continue::
    end
end

vim.api.nvim_create_user_command(
    "Bd",
    close_allbuf_except_current,
    { desc = "Close all buffers except current", bang = true }
)
