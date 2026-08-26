local list_actions = require("users.snacks.list_actions")

local M = {}

local qflist = list_actions.make({
    list_name = "quickfix",
    get_entries = function(_)
        local qf = vim.fn.getqflist({ all = true })
        return qf.items or {}, qf
    end,
    set_entries = function(_, entries, qf)
        vim.fn.setqflist({}, "r", {
            title = qf.title,
            context = qf.context,
            items = entries,
            idx = math.min(qf.idx or 1, math.max(#entries, 1)),
        })
    end,
})

function M.remove_qflist_items(picker, item)
    qflist.remove_selected(picker, item)
end

function M.clear_qflist(picker)
    qflist.clear_all(picker)
end

function M.make_loclist_actions(target_win)
    local loclist = list_actions.make({
        list_name = "loclist",
        get_entries = function(_)
            local ll = vim.fn.getloclist(target_win, { all = true })
            return ll.items or {}, ll
        end,
        set_entries = function(_, entries, ll)
            vim.fn.setloclist(target_win, {}, "r", {
                title = ll.title,
                context = ll.context,
                items = entries,
                idx = math.min(ll.idx or 1, math.max(#entries, 1)),
            })
        end,
    })

    return {
        remove_loclist_items = loclist.remove_selected,
        clear_loclist = loclist.clear_all,
    }
end

return M
