local M = {}

local function toggle_spell()
    local ok, notify = pcall(require, "notify")
    if vim.o.spell then
        vim.o.spell = false
        if ok then
            notify.notify("Spell turned off")
        end
    else
        vim.o.spell = true
        if ok then
            notify.notify("Spell turned on")
        end
    end
end

function M.setup()
    vim.api.nvim_create_user_command("Spell", toggle_spell, { desc = "Toggle spell" })

    vim.api.nvim_create_user_command("Df", function(opts)
        local args = table.concat(opts.fargs, " ")
        vim.cmd(("DiffviewOpen %s"):format(args))
    end, { nargs = "*" })

    vim.api.nvim_create_user_command("T", function(opts)
        local args = table.concat(opts.fargs, " ")
        vim.cmd(("tab split | %s"):format(args))
    end, { nargs = "*", desc = "Create a tab and execute command" })

    vim.api.nvim_create_user_command("Tvd", function(opts)
        if #opts.fargs == 0 then
            return
        end
        vim.cmd("tab split | vertical diffsplit " .. opts.fargs[1])
    end, { nargs = 1, desc = "Create a tab and diff the file with current buffer" })
end

return M
