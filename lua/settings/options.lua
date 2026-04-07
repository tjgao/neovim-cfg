local tabwidth = 4
local options = {
    backup = false,                               -- creates backup file
    spelllang = "en_au",                          -- spell checking language
    swapfile = false,                             -- creates swap file
    clipboard = "unnamedplus",                    -- allows neovim to access the system clipboard
    ignorecase = true,                            -- ignores case in search
    smartcase = true,                             -- smart case, search pattern in lower case will ignore case, otherwise not
    fileencoding = "utf-8",                       -- the encoding used in writing files
    completeopt = { "menuone", "noselect" },      -- for cmp
    termguicolors = true,                         -- for most terminals this is supported
    mouse = "a",                                  -- allows mouse use
    tabstop = tabwidth,                           -- inserts 'tabwidth' spaces for a tab
    shiftwidth = tabwidth,                        -- the number of spaces inserted for each indentation
    softtabstop = tabwidth,                       -- how many columns (spaces) cursor moves right for a tab press, and left for a BS
    wrap = false,                                 -- do not wrap long lines
    expandtab = true,                             -- converts tabs to spaces
    number = true,                                -- shows line numbers
    relativenumber = false,                       -- shows relative line numbers
    scrolloff = 8,                                -- always leaves some space above/below if possible
    sidescrolloff = 8,                            -- always leaves some space left/right if possible
    numberwidth = 4,                              -- the width for line number
    signcolumn = "yes",                           -- allows to show sign column
    splitbelow = true,                            -- force horizontal splits to go below
    splitright = true,                            -- force vertical spllits to go right
    wildmode = "longest:full",                    -- do not want auto select for wildmenu
    guifont = "UbuntuMono Nerd Font Regular:h16", -- font used in GUI neovim app

    updatetime = 400,
    colorcolumn = "120",
    conceallevel = 1,
}

vim.opt.shortmess:append("c")

for k, v in pairs(options) do
    vim.opt[k] = v
end

vim.diagnostic.config({
    virtual_text = false,
    underline = false,
    jump = { float = true },
})

-- disable tmux nav when zoomed
vim.g.tmux_navigator_disable_when_zoomed = 1
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Better diff for moved/changed code blocks
vim.opt.diffopt = {
    "internal",
    "filler",
    "closeoff",
    "algorithm:histogram",
    "indent-heuristic",
}

-- Fold unchanged sections in diff mode
vim.opt.foldmethod = "diff"

if vim.fn.has("wsl") == 1 and vim.fn.executable("win32yank.exe") == 1 then
    local clipboard_cache = {
        ["+"] = nil,
        ["*"] = nil,
    }

    local function set_cache(lines, regtype)
        local value = {
            lines = vim.deepcopy(lines),
            regtype = regtype or "v",
        }
        clipboard_cache["+"] = value
        clipboard_cache["*"] = value
    end

    local function clipboard_copy(lines, regtype)
        local text = table.concat(lines, "\n")
        local job = vim.fn.jobstart({ "win32yank.exe", "-i", "--crlf" }, { stdin = "pipe" })
        if job <= 0 then
            return
        end
        vim.fn.chansend(job, text)
        vim.fn.chanclose(job, "stdin")
        set_cache(lines, regtype)
    end

    local function clipboard_paste(reg)
        local cached = clipboard_cache[reg]
        if cached then
            return vim.deepcopy(cached.lines), cached.regtype
        end
        return vim.fn.systemlist("win32yank.exe -o --lf"), "v"
    end

    vim.api.nvim_create_autocmd({ "FocusGained", "VimResume" }, {
        group = vim.api.nvim_create_augroup("wsl-clipboard-cache", { clear = true }),
        callback = function()
            clipboard_cache["+"] = nil
            clipboard_cache["*"] = nil
        end,
    })

    vim.g.clipboard = {
        name = "win32yank-wsl",
        copy = {
            ["+"] = clipboard_copy,
            ["*"] = clipboard_copy,
        },
        paste = {
            ["+"] = function()
                return clipboard_paste("+")
            end,
            ["*"] = function()
                return clipboard_paste("*")
            end,
        },
        cache_enabled = 0,
    }
end
