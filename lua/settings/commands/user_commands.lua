local M = {}
local notify = require("shared.notify")
local git_async = require("users.git.async")
local git_completion = require("users.git.completion")

local function short_gitlog(args)
    vim.cmd('G log --pretty=format:"%h%x09%an%x09%ad%x09%s" --date=short ' .. args.args)
end

local git_branch_complete = function(_, CmdLine, _)
    local lst = {}
    local cmd = vim.split(vim.trim(CmdLine), " ")
    if #cmd > 0 then
        local obj = vim.system({ "git", "branch" }, { text = true }):wait()
        if obj and obj.code == 0 then
            for _, val in ipairs(vim.split(obj.stdout, "\n")) do
                val = string.gsub(vim.trim(val), "^*%s*", "")
                if val ~= "" then
                    table.insert(lst, val)
                end
            end
        end
    end
    return lst
end

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
    end, {
        nargs = "*",
        desc = "Git pull (async, passes args)",
        complete = function(arg_lead, cmd_line, _)
            return git_completion.complete_pull(arg_lead, cmd_line)
        end,
    })

    vim.api.nvim_create_user_command("Gu", function(opts)
        local args = { "push" }
        vim.list_extend(args, opts.fargs)

        run_git_background(args, {
            progress_message = "Pushing to upstream...",
            success_message = "Push completed",
            error_prefix = "Git push failed",
            id_prefix = "git-push",
        })
    end, {
        nargs = "*",
        desc = "Git push (async, passes args)",
        complete = function(arg_lead, cmd_line, _)
            return git_completion.complete_push(arg_lead, cmd_line)
        end,
    })

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
    end, {
        nargs = "*",
        desc = "Git fetch (async, defaults to origin)",
        complete = function(arg_lead, cmd_line, _)
            return git_completion.complete_fetch(arg_lead, cmd_line)
        end,
    })

    vim.api.nvim_create_user_command("Gk", function(opts)
        local args = { "checkout" }
        vim.list_extend(args, opts.fargs)

        run_git_background(args, {
            progress_message = "Running checkout...",
            success_message = "Checkout completed",
            error_prefix = "Git checkout failed",
            id_prefix = "git-checkout",
        })
    end, {
        nargs = "*",
        desc = "Git checkout (async, passes args)",
        complete = function(arg_lead, _, _)
            return git_completion.complete_checkout(arg_lead)
        end,
    })

    vim.api.nvim_create_user_command("Gl", short_gitlog, {
        nargs = "*",
        complete = git_branch_complete,
        desc = "One line git log",
    })

    vim.api.nvim_create_user_command("Gb", function(args)
        vim.cmd("G branch " .. args.args)
    end, {
        nargs = "*",
        desc = "Shortcut for git branch",
    })

    vim.api.nvim_create_user_command("Gc", function(opts)
        local args = vim.trim(opts.args or "")
        if args == "" then
            vim.cmd("G commit")
            return
        end
        vim.cmd(("G commit %s"):format(args))
    end, {
        nargs = "*",
        desc = "Git commit",
        complete = function(arg_lead, _, _)
            return git_completion.complete_commit(arg_lead)
        end,
    })
end

return M
