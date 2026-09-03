if vim.g.neovide then
    require("vim._core.ui2").enable()
    -- vim.deprecate = function() end
    -- local original_deprecate = vim.deprecate

    -- vim.deprecate = function(name, alternative, version, opts)
    --     vim.notify(
    --         string.format("%s is deprecated%s", name, alternative and (", use " .. alternative .. " instead") or ""),
    --         vim.log.levels.WARN
    --     )
    -- end
    local uv = vim.uv or vim.loop
    local server = vim.fn.stdpath("state") .. "/neovide.sock"
    local stat = uv.fs_stat(server)
    local should_start = true

    if stat then
        local chan = vim.fn.sockconnect("pipe", server, { rpc = true })
        if type(chan) == "number" and chan > 0 then
            should_start = false
            pcall(vim.fn.chanclose, chan)
        else
            pcall(uv.fs_unlink, server)
        end
    end

    if should_start then
        pcall(vim.fn.serverstart, server)
    end
end

require("settings.options")
require("lazy-nvim")
require("settings.keymaps")
require("settings.commands")
require("users.buf_close")
require("users.skip")
require("users.ts_breadcrumb")
