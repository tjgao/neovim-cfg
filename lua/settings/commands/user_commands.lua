local M = {}
local git_async = require("users.git.async")
local git_completion = require("users.git.completion")
local git_rg = require("users.snacks.git_rg")

local flyout_cmd_opts = {
    nargs = "+",
}

if vim.fn.has("wsl") ~= 1 then
    flyout_cmd_opts.complete = "shellcmd"
end

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
        vim.notify("Spell turned off")
    else
        vim.o.spell = true
        vim.notify("Spell turned on")
    end
end

local function resolve_search_pattern(raw)
    local pattern = vim.trim(raw or "")
    if pattern == "" then
        pattern = vim.fn.getreg("/")
    end

    if pattern == "" then
        vim.notify("No search pattern found", vim.log.levels.WARN, { title = "Search" })
        return nil
    end

    return pattern
end

local function run_search_to_list(kind, pattern, target)
    if vim.fn.executable("rg") ~= 1 then
        vim.notify("ripgrep (rg) is not available", vim.log.levels.ERROR, { title = "Search" })
        return
    end

    local targets = {}
    if type(target) == "table" then
        targets = target
    elseif target == "%" then
        local file = vim.api.nvim_buf_get_name(0)
        if file ~= "" then
            targets = { file }
        end
    elseif target == "**/*" then
        targets = { "." }
    else
        targets = { target }
    end

    if #targets == 0 then
        if kind == "loclist" then
            vim.fn.setloclist(0, {})
        else
            vim.fn.setqflist({})
        end
        vim.notify("No matches found", vim.log.levels.INFO, { title = "Search" })
        return
    end

    local args = {
        "--vimgrep",
        "--no-heading",
        "--color",
        "never",
        "--smart-case",
        "--",
        pattern,
    }
    vim.list_extend(args, targets)

    local cmd = { "rg" }
    vim.list_extend(cmd, args)
    local proc = vim.system(cmd, { text = true }):wait()

    if proc.code == 1 then
        if kind == "loclist" then
            vim.fn.setloclist(0, {})
        else
            vim.fn.setqflist({})
        end
        vim.notify("No matches found", vim.log.levels.INFO, { title = "Search" })
        return
    end

    if proc.code ~= 0 then
        local err = vim.trim(proc.stderr or "")
        if err == "" then
            err = "rg failed"
        end
        vim.notify(err, vim.log.levels.ERROR, { title = "Search" })
        return
    end

    local items = {}
    for line in (proc.stdout or ""):gmatch("[^\r\n]+") do
        local filename, lnum, col, text = line:match("^(.-):(%d+):(%d+):(.*)$")
        if filename then
            items[#items + 1] = {
                filename = filename,
                lnum = tonumber(lnum),
                col = tonumber(col),
                text = text,
            }
        end
    end

    if #items == 0 then
        if kind == "loclist" then
            vim.fn.setloclist(0, {})
        else
            vim.fn.setqflist({})
        end
        vim.notify("No matches found", vim.log.levels.INFO, { title = "Search" })
        return
    end

    if kind == "loclist" then
        vim.fn.setloclist(0, {}, " ", { title = "Search", items = items })
        vim.cmd("lopen")
    else
        vim.fn.setqflist({}, " ", { title = "Search", items = items })
        vim.cmd("copen")
    end
end

local function get_git_tracked_files()
    local root = git_async.resolve_git_root(vim.fn.getcwd())
    if not root then
        return nil
    end

    local files = {}
    for _, file in ipairs(git_rg.get_git_tracked_files(root)) do
        files[#files + 1] = vim.fs.joinpath(root, file)
    end
    return files
end

local function run_git_background(args, opts)
    opts = opts or {}

    local root = git_async.resolve_git_root(vim.fn.getcwd())
    if not root then
        vim.notify("Not inside a git repository", vim.log.levels.WARN, { title = "Git" })
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
                vim.notify((opts.error_prefix or "Git command failed") .. ": " .. err, vim.log.levels.ERROR, {
                    title = "Git",
                })
                return
            end

            local out = vim.trim(proc.stdout or "")
            if out ~= "" then
                vim.notify(out, vim.log.levels.INFO, { title = "Git" })
                return
            end

            vim.notify(opts.success_message or "Git command completed", vim.log.levels.INFO, {
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

    vim.api.nvim_create_user_command("Sq", function(opts)
        local pattern = resolve_search_pattern(opts.args)
        if not pattern then
            return
        end

        if opts.bang then
            local tracked_files = get_git_tracked_files()
            if tracked_files then
                run_search_to_list("quickfix", pattern, tracked_files)
            else
                vim.notify("Not in a git repo, fallback to all files", vim.log.levels.INFO, { title = "Search" })
                run_search_to_list("quickfix", pattern, "**/*")
            end
            return
        end
        run_search_to_list("quickfix", pattern, "%")
    end, {
        nargs = "*",
        bang = true,
        desc = "Search to quickfix (%; ! for git tracked files)",
    })

    vim.api.nvim_create_user_command("Sl", function(opts)
        local pattern = resolve_search_pattern(opts.args)
        if not pattern then
            return
        end

        if opts.bang then
            local tracked_files = get_git_tracked_files()
            if tracked_files then
                run_search_to_list("loclist", pattern, tracked_files)
            else
                vim.notify("Not in a git repo, fallback to all files", vim.log.levels.INFO, { title = "Search" })
                run_search_to_list("loclist", pattern, "**/*")
            end
            return
        end
        run_search_to_list("loclist", pattern, "%")
    end, {
        nargs = "*",
        bang = true,
        desc = "Search to loclist (%; ! for git tracked files)",
    })

    vim.api.nvim_create_user_command("Osv", function()
        local osv = require("osv")
        if osv.is_running() then
            osv.stop()
            vim.notify("OSV stopped", vim.log.levels.INFO)
        else
            osv.launch({ port = 8086, block = false })
            vim.notify("OSV started", vim.log.levels.INFO)
        end
    end, {})

    vim.api.nvim_create_user_command("F", "Flyout <args>", flyout_cmd_opts)
end

return M
