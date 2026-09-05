local IMAGE_EXTENSIONS = {
    png = true,
    jpg = true,
    jpeg = true,
    gif = true,
    bmp = true,
    webp = true,
    avif = true,
    heic = true,
    heif = true,
    tif = true,
    tiff = true,
    svg = true,
}

local function is_image(path)
    local ext = vim.fn.fnamemodify(path or "", ":e"):lower()
    return IMAGE_EXTENSIONS[ext] == true
end

local function is_pdf(path)
    local ext = vim.fn.fnamemodify(path or "", ":e"):lower()
    return ext == "pdf"
end

local function open_image_external(path)
    if vim.fn.executable("kitty") == 1 and vim.fn.executable("sxiv") == 1 then
        vim.fn.jobstart({ "kitty", "--detach", "sxiv", path }, { detach = true })
        return true
    end
    if vim.fn.executable("sxiv") == 1 then
        vim.fn.jobstart({ "sxiv", path }, { detach = true })
        return true
    end
    if vim.fn.executable("xdg-open") == 1 then
        vim.fn.jobstart({ "xdg-open", path }, { detach = true })
        return true
    end
    return false
end

local function open_pdf_external(path)
    if vim.fn.executable("kitty") == 1 and vim.fn.executable("zathura") == 1 then
        vim.fn.jobstart({ "kitty", "--detach", "zathura", path }, { detach = true })
        return true
    end
    if vim.fn.executable("zathura") == 1 then
        vim.fn.jobstart({ "zathura", path }, { detach = true })
        return true
    end
    if vim.fn.executable("xdg-open") == 1 then
        vim.fn.jobstart({ "xdg-open", path }, { detach = true })
        return true
    end
    return false
end

local function yazi_with_chafa(mode)
    local old_wayland = vim.env.WAYLAND_DISPLAY
    local old_display = vim.env.DISPLAY
    local old_session = vim.env.XDG_SESSION_TYPE

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
        set_keymappings_function = function(yazi_buffer, _, context)
            vim.keymap.set("t", "<C-p>", function()
                local hovered = context.ya_process.hovered_url
                if type(hovered) ~= "string" or hovered == "" then
                    vim.notify("No file hovered", vim.log.levels.WARN)
                    return
                end

                if is_image(hovered) then
                    if not open_image_external(hovered) then
                        vim.notify("No image opener found (kitty/sxiv/xdg-open)", vim.log.levels.ERROR)
                    end
                    return
                end

                if is_pdf(hovered) then
                    if not open_pdf_external(hovered) then
                        vim.notify("No PDF opener found (kitty+zathura/zathura/xdg-open)", vim.log.levels.ERROR)
                    end
                    return
                end

                vim.notify("Hovered file is not an image or PDF", vim.log.levels.INFO)
            end, { buffer = yazi_buffer, silent = true, desc = "Open hovered image/PDF externally" })
        end,
        keymaps = {
            show_help = "<leader>sy",
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
