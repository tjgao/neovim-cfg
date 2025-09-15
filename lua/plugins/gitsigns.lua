if not table.unpack then
    table.unpack = unpack
end

local function gitsigns_blame(args)
    vim.cmd("Gitsigns blame " .. args.args)
end

vim.api.nvim_create_user_command("Gb", gitsigns_blame, {
    desc = "Gitsigns blame",
})

local group = vim.api.nvim_create_augroup("GitsignsGroup", {})

local function search_commit()
    local commit = nil
    local r, _ = unpack(vim.api.nvim_win_get_cursor(0))
    local get_commit_from_line = require("shared.utils").get_commit_from_line
    while r > 0 and commit == nil do
        commit = get_commit_from_line(r)
        r = r - 1
    end
    return commit
end

vim.api.nvim_create_autocmd("FileType", {
    pattern = "gitsigns-blame",
    group = group,
    callback = function(ctx)
        vim.keymap.set("n", "gq", function()
            vim.cmd(":bd")
        end, { buffer = true })
        vim.keymap.set("n", "d", function()
            local commit = search_commit()
            if commit ~= nil then
                vim.cmd(("DiffviewOpen %s^!"):format(commit))
            end
        end, { buffer = ctx.buf })
        vim.keymap.set("n", "D", function()
            local commit = search_commit()
            if commit ~= nil then
                vim.cmd(("DiffviewOpen %s"):format(commit))
            end
        end, { buffer = ctx.buf })
    end,
})

return {
    "lewis6991/gitsigns.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
    },
    -- tag = 'release' -- To use the latest release
    config = function()
        require("gitsigns").setup({
            --  signs = {
            --    add          = {hl = 'GitSignsAdd'   , text = '│', numhl='GitSignsAddNr'   , linehl='GitSignsAddLn'},
            --    change       = {hl = 'GitSignsChange', text = '│', numhl='GitSignsChangeNr', linehl='GitSignsChangeLn'},
            --    delete       = {hl = 'GitSignsDelete', text = '_', numhl='GitSignsDeleteNr', linehl='GitSignsDeleteLn'},
            --    topdelete    = {hl = 'GitSignsDelete', text = '‾', numhl='GitSignsDeleteNr', linehl='GitSignsDeleteLn'},
            --    changedelete = {hl = 'GitSignsChange', text = '~', numhl='GitSignsChangeNr', linehl='GitSignsChangeLn'},
            --  },
            signs = {
                add = {
                    text = "+",
                },
                change = {
                    text = "^",
                },
                delete = {
                    text = "-",
                },
                topdelete = {
                    text = "‾",
                },
                changedelete = {
                    text = "~",
                },
            },
            signcolumn = true, -- Toggle with `:Gitsigns toggle_signs`
            numhl = false,     -- Toggle with `:Gitsigns toggle_numhl`
            linehl = false,    -- Toggle with `:Gitsigns toggle_linehl`
            word_diff = false, -- Toggle with `:Gitsigns toggle_word_diff`
            watch_gitdir = {
                interval = 1000,
                follow_files = true,
            },
            attach_to_untracked = true,
            current_line_blame = false, -- Toggle with `:Gitsigns toggle_current_line_blame`
            current_line_blame_opts = {
                virt_text = true,
                virt_text_pos = "eol", -- 'eol' | 'overlay' | 'right_align'
                delay = 1000,
                ignore_whitespace = false,
            },
            current_line_blame_formatter = "<author>, <author_time:%Y-%m-%d> - <summary>",
            sign_priority = 6,
            update_debounce = 100,
            status_formatter = nil, -- Use default
            max_file_length = 40000,
            preview_config = {
                -- Options passed to nvim_open_win
                border = "single",
                style = "minimal",
                relative = "cursor",
                row = 0,
                col = 1,
            },
        })
    end,
}
