return {
    "nvim-treesitter/nvim-treesitter-textobjects",
    depdendencies = { "nvim-treesitter/nvim-treesitter" },
    branch = "main",
    init = function()
        -- Disable entire built-in ftplugin mappings to avoid conflicts.
        -- See https://github.com/neovim/neovim/tree/master/runtime/ftplugin for built-in ftplugins.
        vim.g.no_plugin_maps = true
    end,
    config = function()
        require("nvim-treesitter-textobjects").setup({
            select = {
                enable = true,

                -- Automatically jump forward to textobj, similar to targets.vim
                lookahead = true,

                -- You can choose the select mode (default is charwise 'v')
                --
                -- Can also be a function which gets passed a table with the keys
                -- * query_string: eg '@function.inner'
                -- * method: eg 'v' or 'o'
                -- and should return the mode ('v', 'V', or '<c-v>') or a table
                -- mapping query_strings to modes.
                selection_modes = {
                    ["@parameter.outer"] = "v", -- charwise
                    ["@function.outer"] = "V", -- linewise
                    ["@class.outer"] = "<c-v>", -- blockwise
                },
                -- If you set this to `true` (default is `false`) then any textobject is
                -- extended to include preceding or succeeding whitespace. Succeeding
                -- whitespace has priority in order to act similarly to eg the built-in
                -- `ap`.
                --
                -- Can also be a function which gets passed a table with the keys
                -- * query_string: eg '@function.inner'
                -- * selection_mode: eg 'v'
                -- and should return true or false
                -- include_surrounding_whitespace = true,
            },
        })
        -- the following config conflict with flash.nvim, disable for now
        -- local ts_repeat_move = require("nvim-treesitter.textobjects.repeatable_move")
        -- vim.keymap.set({ "n", "o", "x" }, ";", ts_repeat_move.repeat_last_move_next)
        -- vim.keymap.set({ "n", "o", "x" }, ",", ts_repeat_move.repeat_last_move_previous)
        --
        -- vim.keymap.set({ "n", "o", "x" }, "f", ts_repeat_move.builtin_f_expr, { expr = true })
        -- vim.keymap.set({ "n", "o", "x" }, "F", ts_repeat_move.builtin_F_expr, { expr = true })
        -- vim.keymap.set({ "n", "o", "x" }, "t", ts_repeat_move.builtin_t_expr, { expr = true })
        -- vim.keymap.set({ "n", "o", "x" }, "T", ts_repeat_move.builtin_T_expr, { expr = true })

        local sel = require("nvim-treesitter-textobjects.select")

        vim.keymap.set({ "x", "o" }, "am", function()
            sel.select_textobject("@caller.outer", "textobjects")
        end, { desc = "Select caller outer" })
        vim.keymap.set({ "x", "o" }, "im", function()
            sel.select_textobject("@caller.inner", "textobjects")
        end, { desc = "Select caller inner" })
        vim.keymap.set({ "x", "o" }, "af", function()
            sel.select_textobject("@function.outer", "textobjects")
        end, { desc = "Select function outer" })
        vim.keymap.set({ "x", "o" }, "if", function()
            sel.select_textobject("@function.inner", "textobjects")
        end, { desc = "Select function inner" })
        vim.keymap.set({ "x", "o" }, "aa", function()
            sel.select_textobject("@class.outer", "textobjects")
        end, { desc = "Select class outer" })
        vim.keymap.set({ "x", "o" }, "ia", function()
            sel.select_textobject("@class.inner", "textobjects")
        end, { desc = "Select class inner" })
        vim.keymap.set({ "x", "o" }, "ai", function()
            sel.select_textobject("@conditional.outer", "textobjects")
        end, { desc = "Select conditional outer" })
        vim.keymap.set({ "x", "o" }, "ii", function()
            sel.select_textobject("@conditional.inner", "textobjects")
        end, { desc = "Select conditional inner" })

        vim.keymap.set({ "x", "o" }, "al", function()
            sel.select_textobject("@loop.outer", "textobjects")
        end, { desc = "Select loop outer" })
        vim.keymap.set({ "x", "o" }, "il", function()
            sel.select_textobject("@loop.inner", "textobjects")
        end, { desc = "Select loop inner" })

        vim.keymap.set({ "x", "o" }, "a=", function()
            sel.select_textobject("@assignment.outer", "textobjects")
        end, { desc = "Select assignment outer" })
        vim.keymap.set({ "x", "o" }, "i=", function()
            sel.select_textobject("@assignment.inner", "textobjects")
        end, { desc = "Select assignment inner" })

        vim.keymap.set({ "x", "o" }, "l=", function()
            sel.select_textobject("@assignment.lhs", "textobjects")
        end, { desc = "Select lhs of assignment" })
        vim.keymap.set({ "x", "o" }, "r=", function()
            sel.select_textobject("@assignment.rhs", "textobjects")
        end, { desc = "Select rhs of assignment" })
        -- You can also use captures from other query groups like `locals.scm`
        vim.keymap.set({ "x", "o" }, "as", function()
            require("nvim-treesitter-textobjects.select").select_textobject("@local.scope", "locals")
        end, { desc = "Select local scope" })

        ----------------------------------------------------------
        local mv = require("nvim-treesitter-textobjects.move")
        vim.keymap.set({ "n", "x", "o" }, "]f", function()
            mv.goto_next_start("@function.outer", "textobjects")
        end, { desc = "Goto next function outer start" })
        vim.keymap.set({ "n", "x", "o" }, "]F", function()
            mv.goto_next_end("@function.outer", "textobjects")
        end, { desc = "Goto next function outer end" })
        vim.keymap.set({ "n", "x", "o" }, "]i", function()
            mv.goto_next_start("@conditional.outer", "textobjects")
        end, { desc = "Goto next conditional outer start" })
        vim.keymap.set({ "n", "x", "o" }, "]I", function()
            mv.goto_next_end("@conditional.outer", "textobjects")
        end, { desc = "Goto next conditional outer end" })
        vim.keymap.set({ "n", "x", "o" }, "]a", function()
            mv.goto_next_start("@class.outer", "textobjects")
        end, { desc = "Goto next class outer start" })
        vim.keymap.set({ "n", "x", "o" }, "]A", function()
            mv.goto_next_end("@class.outer", "textobjects")
        end, { desc = "Goto next class outer end" })
        -- You can also pass a list to group multiple queries.
        vim.keymap.set({ "n", "x", "o" }, "]l", function()
            mv.goto_next_start({ "@loop.inner", "@loop.outer" }, "textobjects")
        end, { desc = "Goto next loop outer start" })
        vim.keymap.set({ "n", "x", "o" }, "]L", function()
            mv.goto_next_end({ "@loop.inner", "@loop.outer" }, "textobjects")
        end, { desc = "Goto next loop outer end" })
        -- You can also use captures from other query groups like `locals.scm` or `folds.scm`
        vim.keymap.set({ "n", "x", "o" }, "]s", function()
            mv.goto_next_start("@local.scope", "locals")
        end, { desc = "Goto next local scope start" })
        vim.keymap.set({ "n", "x", "o" }, "]S", function()
            mv.goto_next_end("@local.scope", "locals")
        end, { desc = "Goto next local scope end" })
        vim.keymap.set({ "n", "x", "o" }, "[s", function()
            mv.goto_previous_start("@local.scope", "locals")
        end, { desc = "Goto previous local scope start" })
        vim.keymap.set({ "n", "x", "o" }, "[S", function()
            mv.goto_previous_end("@local.scope", "locals")
        end, { desc = "Goto previous local scope end" })
        vim.keymap.set({ "n", "x", "o" }, "]z", function()
            mv.goto_next_start("@fold", "folds")
        end, { desc = "Goto next fold" })
        vim.keymap.set({ "n", "x", "o" }, "[z", function()
            mv.goto_previous_start("@fold", "folds")
        end, { desc = "Goto previous fold" })
        vim.keymap.set({ "n", "x", "o" }, "[a", function()
            mv.goto_previous_start("@class.outer", "textobjects")
        end, { desc = "Goto previous class outer start" })
        vim.keymap.set({ "n", "x", "o" }, "[A", function()
            mv.goto_previous_end("@class.outer", "textobjects")
        end, { desc = "Goto previous class outer end" })
        vim.keymap.set({ "n", "x", "o" }, "[f", function()
            mv.goto_previous_start("@function.outer", "textobjects")
        end, { desc = "Goto previous function outer start" })
        vim.keymap.set({ "n", "x", "o" }, "[F", function()
            mv.goto_previous_end("@function.outer", "textobjects")
        end, { desc = "Goto previous function outer end" })
        vim.keymap.set({ "n", "x", "o" }, "[i", function()
            mv.goto_previous_start("@conditional.outer", "textobjects")
        end, { desc = "Goto previous conditional outer start" })
        vim.keymap.set({ "n", "x", "o" }, "[I", function()
            mv.goto_previous_end("@conditional.outer", "textobjects")
        end, { desc = "Goto previous conditional outer end" })
        vim.keymap.set({ "n", "x", "o" }, "[l", function()
            mv.goto_previous_start({ "@loop.inner", "@loop.outer" }, "textobjects")
        end, { desc = "Goto previous loop outer start" })
        vim.keymap.set({ "n", "x", "o" }, "[L", function()
            mv.goto_previous_end({ "@loop.inner", "@loop.outer" }, "textobjects")
        end, { desc = "Goto previous loop outer end" })
    end,
}
