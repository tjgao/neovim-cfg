local git_actions = require("users.snacks.git_actions")
local notify = require("shared.notify")

local M = {}

local SHOW_REMOTE_BRANCHES = false

local function set_hl_bold(name)
    local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
    if not ok then
        return
    end

    vim.api.nvim_set_hl(0, name, {
        fg = hl.fg,
        bg = hl.bg,
        sp = hl.sp,
        bold = true,
        italic = hl.italic,
        reverse = hl.reverse,
        underline = hl.underline,
        undercurl = hl.undercurl,
        strikethrough = hl.strikethrough,
        nocombine = hl.nocombine,
        blend = hl.blend,
    })
end

local function ensure_git_branch_highlights()
    vim.api.nvim_set_hl(0, "SnacksPickerGitBranchRemote", { default = true, link = "DiagnosticHint" })
    set_hl_bold("SnacksPickerGitBranch")
    set_hl_bold("SnacksPickerGitBranchRemote")
end

function M.open_git_branches_picker()
    ensure_git_branch_highlights()

    local function selected_branch_items(picker, item)
        local selected = {}
        if picker and type(picker.selected) == "function" then
            selected = picker:selected({ fallback = true })
        end
        if #selected == 0 and item then
            selected = { item }
        end

        local seen = {}
        local ret = {}
        for _, it in ipairs(selected) do
            if type(it) == "table" and type(it.branch) == "string" and it.branch ~= "" and not seen[it.branch] then
                seen[it.branch] = true
                ret[#ret + 1] = it
            end
        end
        return ret
    end

    local function delete_selected_branches(picker, item, force_local)
        local selected = selected_branch_items(picker, item)
        if #selected == 0 then
            notify.notify("No branch selected", vim.log.levels.WARN)
            return
        end

        local local_items = {}
        local remote_items = {}
        local skipped_current = {}

        for _, it in ipairs(selected) do
            local remote, remote_branch = it.branch:match("^remotes/([^/]+)/(.+)$")
            if remote and remote_branch then
                remote_items[#remote_items + 1] = {
                    item = it,
                    remote = remote,
                    branch = remote_branch,
                }
            elseif it.current then
                skipped_current[#skipped_current + 1] = it.branch
            else
                local_items[#local_items + 1] = it
            end
        end

        if #local_items == 0 and #remote_items == 0 then
            notify.notify("No deletable branches selected", vim.log.levels.WARN)
            return
        end

        local local_mode = force_local and "force" or "safe"
        local prompt = ("Delete %d local (%s) and %d remote branch(es)?"):format(
            #local_items,
            local_mode,
            #remote_items
        )
        local ok = vim.fn.confirm(prompt, "&No\n&Yes", 1)
        if ok ~= 2 then
            return
        end

        local deleted = {}
        local failed = {}

        for _, ri in ipairs(remote_items) do
            local proc = vim.system({ "git", "push", ri.remote, "--delete", ri.branch }, {
                cwd = ri.item.cwd,
                text = true,
            }):wait()
            if proc.code == 0 then
                deleted[#deleted + 1] = ("remote:%s/%s"):format(ri.remote, ri.branch)
            else
                local err = vim.trim(proc.stderr or "")
                if err == "" then
                    err = vim.trim(proc.stdout or "")
                end
                failed[#failed + 1] = ("remote:%s/%s (%s)"):format(ri.remote, ri.branch, err ~= "" and err or "failed")
            end
        end

        for _, li in ipairs(local_items) do
            local flag = force_local and "-D" or "-d"
            local proc = vim.system({ "git", "branch", flag, li.branch }, {
                cwd = li.cwd,
                text = true,
            }):wait()
            if proc.code == 0 then
                deleted[#deleted + 1] = ("local:%s"):format(li.branch)
            else
                local err = vim.trim(proc.stderr or "")
                if err == "" then
                    err = vim.trim(proc.stdout or "")
                end
                failed[#failed + 1] = ("local:%s (%s)"):format(li.branch, err ~= "" and err or "failed")
            end
        end

        if #skipped_current > 0 then
            notify.notify("Skipped current branch: " .. table.concat(skipped_current, ", "), vim.log.levels.WARN)
        end
        if #deleted > 0 then
            notify.notify(("Deleted %d branch(es)"):format(#deleted), vim.log.levels.INFO)
            picker:close()
            vim.schedule(M.open_git_branches_picker)
        end
        if #failed > 0 then
            notify.notify("Failed to delete: " .. table.concat(failed, " | "), vim.log.levels.ERROR)
        end
    end

    require("snacks").picker.pick({
        focus = "list",
        source = "git_branches",
        finder = function(fopts, ctx)
            local base = require("snacks.picker.source.git").branches(fopts, ctx)
            return function(cb)
                base(function(item)
                    if item then
                        item.text = item.branch or "(detached HEAD)"
                    end
                    cb(item)
                end)
            end
        end,
        all = SHOW_REMOTE_BRANCHES,
        title = SHOW_REMOTE_BRANCHES and "Git Branches (local + remote)" or "Git Branches (local)",
        layout = {
            preset = "select",
        },
        format = function(item, picker)
            local Snacks = require("snacks")
            local a = Snacks.picker.util.align
            local ret = {}
            ret[#ret + 1] = item.current and { a("", 2), "SnacksPickerGitBranchCurrent" } or { a("", 2) }

            local w = 60
            if item.detached then
                ret[#ret + 1] = { a("(detached HEAD)", w, { truncate = true }), "SnacksPickerGitDetached" }
            else
                local branch_hl = item.branch and item.branch:match("^remotes/") and "SnacksPickerGitBranchRemote"
                    or "SnacksPickerGitBranch"
                ret[#ret + 1] = { a(item.branch, w, { truncate = true }), branch_hl }
            end

            ret[#ret + 1] = { " " }
            Snacks.picker.highlight.extend(ret, Snacks.picker.format.git_log(item, picker))
            return ret
        end,
        actions = {
            diffview_d = git_actions.diffview_d,
            diffview_D = git_actions.diffview_D,
            diffview_x = git_actions.diffview_x,
            commit_to_cmd = git_actions.commit_to_cmd,
            commit_to_reg = git_actions.commit_to_reg,
            branch_to_cmd = git_actions.branch_to_cmd,
            branch_to_reg = git_actions.branch_to_reg,
            sync_local_branch = function(picker, item)
                git_actions.sync_local_branch(item, { force = false }, function(ok)
                    if ok and picker and not picker.closed and type(picker.find) == "function" then
                        if picker.list and type(picker.list.set_target) == "function" then
                            picker.list:set_target()
                        end
                        picker:find()
                    end
                end)
            end,
            sync_local_branch_force = function(picker, item)
                git_actions.sync_local_branch(item, { force = true }, function(ok)
                    if ok and picker and not picker.closed and type(picker.find) == "function" then
                        if picker.list and type(picker.list.set_target) == "function" then
                            picker.list:set_target()
                        end
                        picker:find()
                    end
                end)
            end,
            sync_and_checkout_local_branch = function(picker, item)
                git_actions.sync_and_checkout_local_branch(item, { force = false }, function(ok, did_checkout)
                    if ok and did_checkout and picker and not picker.closed then
                        picker:close()
                    end
                end)
            end,
            sync_and_checkout_local_branch_force = function(picker, item)
                git_actions.sync_and_checkout_local_branch(item, { force = true }, function(ok, did_checkout)
                    if ok and did_checkout and picker and not picker.closed then
                        picker:close()
                    end
                end)
            end,
            checkout_detached = function(picker, item)
                if not item or not item.commit then
                    notify.notify("No branch selected for detached checkout", vim.log.levels.WARN)
                    return
                end

                local proc = vim.system({ "git", "switch", "--detach", item.commit }, {
                    cwd = item.cwd,
                    text = true,
                }):wait()
                if proc.code ~= 0 then
                    local err = vim.trim(proc.stderr or "")
                    if err == "" then
                        err = vim.trim(proc.stdout or "")
                    end
                    notify.notify(err ~= "" and err or "Detached checkout failed", vim.log.levels.ERROR)
                    return
                end

                picker:close()
                notify.notify(("Detached HEAD at %s"):format(item.commit), vim.log.levels.INFO)
            end,
            delete_branch = function(picker, item)
                delete_selected_branches(picker, item, false)
            end,
            delete_branch_force = function(picker, item)
                delete_selected_branches(picker, item, true)
            end,
            toggle_remote_branches = function(picker)
                SHOW_REMOTE_BRANCHES = not SHOW_REMOTE_BRANCHES
                picker:close()
                vim.schedule(M.open_git_branches_picker)
            end,
        },
        win = {
            list = {
                keys = {
                    ["d"] = {
                        "diffview_d",
                        mode = { "n" },
                    },
                    ["D"] = {
                        "diffview_D",
                        mode = { "n" },
                    },
                    ["x"] = {
                        "diffview_x",
                        mode = { "n" },
                    },
                    ["."] = {
                        "branch_to_cmd",
                        mode = { "n" },
                    },
                    [","] = {
                        "branch_to_reg",
                        mode = { "n" },
                    },
                    ["<S-CR>"] = {
                        "checkout_detached",
                        mode = { "n", "i" },
                    },
                    ["zd"] = {
                        "delete_branch",
                        mode = { "n" },
                    },
                    ["zD"] = {
                        "delete_branch_force",
                        mode = { "n" },
                    },
                    ["zr"] = {
                        "toggle_remote_branches",
                        mode = { "n" },
                    },
                    ["zu"] = {
                        "sync_local_branch",
                        mode = { "n" },
                    },
                    ["zU"] = {
                        "sync_local_branch_force",
                        mode = { "n" },
                    },
                    ["zs"] = {
                        "sync_and_checkout_local_branch",
                        mode = { "n" },
                    },
                    ["zS"] = {
                        "sync_and_checkout_local_branch_force",
                        mode = { "n" },
                    },
                },
            },
            input = {
                keys = {
                    ["d"] = {
                        "diffview_d",
                        mode = { "n" },
                    },
                    ["D"] = {
                        "diffview_D",
                        mode = { "n" },
                    },
                    ["x"] = {
                        "diffview_x",
                        mode = { "n" },
                    },
                    ["."] = {
                        "branch_to_cmd",
                        mode = { "n" },
                    },
                    [","] = {
                        "branch_to_reg",
                        mode = { "n" },
                    },
                    ["<S-CR>"] = {
                        "checkout_detached",
                        mode = { "n", "i" },
                    },
                    ["zd"] = {
                        "delete_branch",
                        mode = { "n" },
                    },
                    ["zD"] = {
                        "delete_branch_force",
                        mode = { "n" },
                    },
                    ["zr"] = {
                        "toggle_remote_branches",
                        mode = { "n" },
                    },
                    ["zu"] = {
                        "sync_local_branch",
                        mode = { "n" },
                    },
                    ["zU"] = {
                        "sync_local_branch_force",
                        mode = { "n" },
                    },
                    ["zs"] = {
                        "sync_and_checkout_local_branch",
                        mode = { "n" },
                    },
                    ["zS"] = {
                        "sync_and_checkout_local_branch_force",
                        mode = { "n" },
                    },
                },
            },
        },
    })
end

return M
