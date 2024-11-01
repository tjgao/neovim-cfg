return {
    "echasnovski/mini.files",
    opts = {
        mappings = {
            toggle_hidden = "g.",
            go_in_horizontal = "<C-s>",
            go_in_vertical = "<C-v>",
            go_in_horizontal_plus = "<C-w>s",
            go_in_vertical_plus = "<C-w>v",
        },
        windows = {
            preview = true,
            width_preview = 60,
            width_focus = 30,
        },
        options = {
            use_as_default_explorer = true,
            permanent_delete = true,
        },
        -- not showing hidden files by default
        content = {
            filter = function(fs_entry)
                return not vim.startswith(fs_entry.name, ".")
            end,
        },
    },
    keys = {
        {
            "<leader>e",
            function()
                require("mini.files").open(vim.api.nvim_buf_get_name(0), true)
            end,
            desc = "Open file's folder [mini-files]",
        },
        {
            "<leader>E",
            function()
                require("mini.files").open(vim.fn.getcwd(), true)
            end,
            desc = "Open current working directory [mini-files]",
        },
    },
    config = function(_, opts)
        require("mini.files").setup(opts)

        -- toggle dot files
        local show_hidden = true
        local show_all = function()
            return true
        end
        local hide_dots = function(fs_entry)
            return not vim.startswith(fs_entry.name, ".")
        end
        local toggle_dot = function()
            local dot_filter = show_hidden and show_all or hide_dots
            require("mini.files").refresh({ content = { filter = dot_filter } })
            show_hidden = not show_hidden
        end

        -- show vertically or horizontally
        local map_split = function(buf_id, lhs, direction, close_on_file)
            local rhs = function()
                local new_target_window
                local cur_target_window = require("mini.files").get_explorer_state().target_window
                if cur_target_window ~= nil then
                    vim.api.nvim_win_call(cur_target_window, function()
                        vim.cmd("belowright " .. direction .. " split")
                        new_target_window = vim.api.nvim_get_current_win()
                    end)

                    require("mini.files").set_target_window(new_target_window)
                    require("mini.files").go_in({ close_on_file = close_on_file })
                end
            end

            local desc = "Open in " .. direction .. " split"
            if close_on_file then
                desc = desc .. " and close"
            end
            vim.keymap.set("n", lhs, rhs, { buffer = buf_id, desc = desc })
        end

        vim.api.nvim_create_autocmd("User", {
            pattern = "MiniFilesBufferCreate",
            callback = function(args)
                local buf_id = args.data.buf_id
                vim.keymap.set(
                    "n",
                    opts.mapping and opts.mappings.toggle_hidden or "g.",
                    toggle_dot,
                    { buffer = buf_id, desc = "Toggle dot files" }
                )

                vim.keymap.set(
                    "n",
                    "<Esc>",
                    require("mini.files").close,
                    { buffer = buf_id, desc = "Close [mini-files]" }
                )

                map_split(buf_id, opts.mappings and opts.mappings.go_in_horizontal or "<C-w>s", "horizontal", false)
                map_split(buf_id, opts.mappings and opts.mappings.go_in_vertical or "<C-w>v", "vertical", false)
                map_split(buf_id, opts.mappings and opts.mappings.go_in_horizontal_plus or "<C-w>S", "horizontal", true)
                map_split(buf_id, opts.mappings and opts.mappings.go_in_vertical_plus or "<C-w>V", "vertical", true)
            end,
        })
    end,
}
