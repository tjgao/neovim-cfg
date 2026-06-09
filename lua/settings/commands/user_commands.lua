local M = {}
local notify = require("shared.notify")
local git_async = require("users.git.async")

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

local function run_git_background(args, opts)
    opts = opts or {}

    local root = git_async.resolve_git_root(vim.fn.getcwd())
    if not root then
        notify.notify("Not inside a git repository", vim.log.levels.WARN, { title = "Git" })
        return
    end

    local done_progress = git_async.start_spinner(opts.progress_message or "Running git command...", {
        title = "Git",
        id_prefix = opts.id_prefix or "git-command",
    })

    local cmd = { "git" }
    vim.list_extend(cmd, args)

    git_async.run(cmd, root, function(proc, err)
        vim.schedule(function()
            done_progress()

            if err then
                notify.notify((opts.error_prefix or "Git command failed") .. ": " .. err, vim.log.levels.ERROR, {
                    title = "Git",
                })
                return
            end

            local out = vim.trim(proc.stdout or "")
            if out ~= "" then
                notify.notify(out, vim.log.levels.INFO, { title = "Git" })
                return
            end

            notify.notify(opts.success_message or "Git command completed", vim.log.levels.INFO, {
                title = "Git",
            })
        end)
    end)
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

    vim.api.nvim_create_user_command("Gp", function()
        run_git_background({ "pull", "--ff-only" }, {
            progress_message = "Pulling from upstream...",
            success_message = "Pull completed (ff-only)",
            error_prefix = "Git pull failed",
            id_prefix = "git-pull",
        })
    end, { desc = "Git pull --ff-only (async)" })

    vim.api.nvim_create_user_command("Gu", function()
        run_git_background({ "push" }, {
            progress_message = "Pushing to upstream...",
            success_message = "Push completed",
            error_prefix = "Git push failed",
            id_prefix = "git-push",
        })
    end, { desc = "Git push (async)" })
end

return M
