-- This lua file provides a command, :Bd or :Bd!
-- It closes all buffers except the current one we are working on
-- If executed with bang (!), the other unsaved buffers will be closed
-- as well. Nvim-tree and terminal buffers are untouched, because that's
-- my preference, I'd like to have them around.
--
-- Close all buffers except current
local function close_allbuf_except_current(opts)
    local cur = vim.api.nvim_win_get_buf(0)
    for _, o in pairs(vim.api.nvim_list_bufs()) do
        if not opts.bang and vim.fn.getbufinfo(o)[1].changed == 1 then
            goto continue
        end
        -- We want to exclude nvim-tree and terminals
        local bt = vim.api.nvim_get_option_value("buftype", { buf = o })
        local ft = vim.api.nvim_get_option_value("filetype", { buf = o })
        if o ~= cur and bt ~= "terminal" and ft ~= "NvimTree" then
            vim.api.nvim_buf_delete(o, { force = opts.bang })
        end
        ::continue::
    end
end

vim.api.nvim_create_user_command(
    "Bd",
    close_allbuf_except_current,
    { desc = "Close all buffers except current", bang = true }
)
