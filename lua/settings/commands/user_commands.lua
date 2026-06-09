local M = {}
local notify = require("shared.notify")
local git_async = require("users.git.async")

local function toggle_spell()
    if vim.o.spell then
        vim.o.spell = false
        notify.notify("Spell turned off")
    else
        vim.o.spell = true
        notify.notify("Spell turned on")
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

    vim.api.nvim_create_user_command("Gp", function(opts)
        local args = { "pull" }
        if #opts.fargs == 0 then
            args[#args + 1] = "--ff-only"
        end
        vim.list_extend(args, opts.fargs)

        run_git_background(args, {
            progress_message = "Pulling from upstream...",
            success_message = "Pull completed",
            error_prefix = "Git pull failed",
            id_prefix = "git-pull",
        })
    end, { nargs = "*", desc = "Git pull (async, passes args)" })

    vim.api.nvim_create_user_command("Gu", function(opts)
        local args = { "push" }
        vim.list_extend(args, opts.fargs)

        run_git_background(args, {
            progress_message = "Pushing to upstream...",
            success_message = "Push completed",
            error_prefix = "Git push failed",
            id_prefix = "git-push",
        })
    end, { nargs = "*", desc = "Git push (async, passes args)" })

    vim.api.nvim_create_user_command("Gf", function(opts)
        local args = { "fetch" }
        if #opts.fargs == 0 then
            args[#args + 1] = "origin"
        end
        vim.list_extend(args, opts.fargs)

        run_git_background(args, {
            progress_message = "Fetching from remote...",
            success_message = "Fetch completed",
            error_prefix = "Git fetch failed",
            id_prefix = "git-fetch",
        })
    end, { nargs = "*", desc = "Git fetch (async, defaults to origin)" })

    vim.api.nvim_create_user_command("Gc", function(opts)
        local args = vim.trim(opts.args or "")
        if args == "" then
            vim.cmd("G commit")
            return
        end
        vim.cmd(("G commit %s"):format(args))
    end, { nargs = "*", desc = "Git commit" })
end

return M
