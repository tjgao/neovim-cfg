local git_actions = require("users.snacks.git_actions")

local M = {}

local function normalize_ref_for_log(ref)
    if type(ref) ~= "string" or ref == "" then
        return ref
    end

    local remote, branch = ref:match("^remotes/([^/]+)/(.+)$")
    if remote and branch then
        return ("%s/%s"):format(remote, branch)
    end

    return ref
end

local function git_log_picker_opts(extra)
    local opts = {
        focus = "list",
        source = "git_log",
        actions = {
            diffview_d = git_actions.diffview_d,
            diffview_D = git_actions.diffview_D,
            diffview_x = git_actions.diffview_x,
            commit_to_cmd = git_actions.commit_to_cmd,
            commit_to_reg = git_actions.commit_to_reg,
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
                        "commit_to_cmd",
                        mode = { "n" },
                    },
                    [","] = {
                        "commit_to_reg",
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
                        "commit_to_cmd",
                        mode = { "n" },
                    },
                    [","] = {
                        "commit_to_reg",
                        mode = { "n" },
                    },
                },
            },
        },
    }

    return vim.tbl_deep_extend("force", opts, extra or {})
end

function M.open(extra)
    require("snacks").picker.pick(git_log_picker_opts(extra))
end

function M.open_for_ref(ref)
    local normalized_ref = normalize_ref_for_log(ref)
    M.open({
        cmd_args = { normalized_ref },
        title = ("Git Log (%s)"):format(normalized_ref),
    })
end

return M
