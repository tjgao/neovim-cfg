local function yazi_with_chafa(mode)
    local old_wayland = vim.env.WAYLAND_DISPLAY
    local old_display = vim.env.DISPLAY
    local old_session = vim.env.XDG_SESSION_TYPE
    local old_orig_wayland = vim.env.YAZI_ORIG_WAYLAND_DISPLAY
    local old_orig_display = vim.env.YAZI_ORIG_DISPLAY
    local old_orig_session = vim.env.YAZI_ORIG_XDG_SESSION_TYPE

    vim.env.YAZI_ORIG_WAYLAND_DISPLAY = old_wayland or ""
    vim.env.YAZI_ORIG_DISPLAY = old_display or ""
    vim.env.YAZI_ORIG_XDG_SESSION_TYPE = old_session or ""

    vim.env.WAYLAND_DISPLAY = nil
    vim.env.DISPLAY = nil
    vim.env.XDG_SESSION_TYPE = "tty"

    if mode == "cwd" then
        require("yazi").yazi(nil, vim.fn.getcwd())
    elseif mode == "toggle" then
        require("yazi").toggle()
    else
        require("yazi").yazi()
    end

    vim.env.WAYLAND_DISPLAY = old_wayland
    vim.env.DISPLAY = old_display
    vim.env.XDG_SESSION_TYPE = old_session
    vim.env.YAZI_ORIG_WAYLAND_DISPLAY = old_orig_wayland
    vim.env.YAZI_ORIG_DISPLAY = old_orig_display
    vim.env.YAZI_ORIG_XDG_SESSION_TYPE = old_orig_session
end

---@type LazySpec
return {
    "mikavilpas/yazi.nvim",
    version = "*", -- use the latest stable version
    event = "VeryLazy",
    dependencies = {
        { "nvim-lua/plenary.nvim", lazy = true },
    },
    keys = {
        -- 👇 in this section, choose your own keymappings!
        {
            "<leader>yf",
            mode = { "n", "v" },
            function()
                yazi_with_chafa()
            end,
            desc = "Open yazi at the current file",
        },
        {
            -- Open in the current working directory
            "<leader>yd",
            function()
                yazi_with_chafa("cwd")
            end,
            desc = "Open the file manager in nvim's working directory",
        },
        {
            "<leader>yy",
            function()
                yazi_with_chafa("toggle")
            end,
            desc = "Resume the last yazi session",
        },
    },
    ---@type table
    opts = {
        config_home = vim.fn.expand("~/.config/yazi-nvim"),
        -- if you want to open yazi instead of netrw, see below for more info
        open_for_directories = false,
        floating_window_scaling_factor = 0.92,
        keymaps = {
            show_help = "<F2>",
        },
    },
    -- 👇 if you use `open_for_directories=true`, this is recommended
    init = function()
        -- mark netrw as loaded so it's not loaded at all.
        --
        -- More details: https://github.com/mikavilpas/yazi.nvim/issues/802
        vim.g.loaded_netrwPlugin = 1
    end,
}
