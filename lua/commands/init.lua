local M = {}

-- Unfortunately, could not figure out how to do this with pure lua
-- winnr, getwinvar's lua alternatives seem to be unavailable
local function get_qf_winnr()
    local ret = vim.api.nvim_eval("filter(range(1, winnr('$')), 'getwinvar(v:val, \"&ft\") == \"qf\"')")
    if ret ~= nil then
        for _, i in pairs(ret) do
            return i
        end
    end
    return 0
end

function M.ToggleQF()
    local winnr = get_qf_winnr()
    if winnr == 0 then
        vim.cmd [[ copen ]]
    else
        vim.cmd [[ cclose ]]
    end
end

return M

