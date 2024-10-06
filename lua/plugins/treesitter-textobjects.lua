return {
    "nvim-treesitter/nvim-treesitter-textobjects",
    depdendencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
        require("nvim-treesitter.configs").setup({
            textobjects = {
                select = {
                    enable = true,

                    -- Automatically jump forward to textobj, similar to targets.vim
                    lookahead = true,

                    keymaps = {
                        -- You can use the capture groups defined in textobjects.scm
                        ["af"] = { query = "@caller.outer", desc = "Select outer part of a function/method call" },
                        ["if"] = { query = "@caller.inner", desc = "Select inner part of a function/method call" },

                        ["am"] = {
                            query = "@function.outer",
                            desc = "Select outer part of a function/method def region",
                        },
                        ["im"] = {
                            query = "@function.inner",
                            desc = "Select inner part of a function/method def region",
                        },
                        ["ac"] = { query = "@class.outer", desc = "Select outer part of a class region" },
                        ["ic"] = { query = "@class.inner", desc = "Select inner part of a class region" },

                        ["as"] = { query = "@scope", query_group = "locals", desc = "Select language scope" },

                        ["il"] = { query = "@loop.inner", desc = "Select inner part of a loop" },
                        ["al"] = { query = "@loop.outer", desc = "Select outer part of a loop" },

                        ["aa"] = { query = "@parameter.outer", desc = "Select outer part of a parameter" },
                        ["ia"] = { query = "@parameter.inner", desc = "Select inner part of a parameter" },

                        ["ai"] = { query = "@conditional.outer", desc = "Select outer part of a conditional" },
                        ["ii"] = { query = "@conditional.inner", desc = "Select inner part of a conditional" },

                        ["au"] = { query = "@attribute.outer", desc = "Select outer part of an attribute" },
                        ["iu"] = { query = "@attribute.inner", desc = "Select inner part of an attribute" },

                        ["a="] = { query = "@assignment.outer", desc = "Select outer part of an assignment" },
                        ["i="] = { query = "@assignment.inner", desc = "Select inner part of an assignment" },
                        ["l="] = { query = "@assignment.lhs", desc = "Select left hand side of an assignment" },
                        ["r="] = { query = "@assignment.rhs", desc = "Select right hand side of an assignment" },
                    },
                    -- You can choose the select mode (default is charwise 'v')
                    --
                    -- Can also be a function which gets passed a table with the keys
                    -- * query_string: eg '@function.inner'
                    -- * method: eg 'v' or 'o'
                    -- and should return the mode ('v', 'V', or '<c-v>') or a table
                    -- mapping query_strings to modes.
                    selection_modes = {
                        ["@parameter.outer"] = "v", -- charwise
                        ["@function.outer"] = "V",  -- linewise
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
                move = {
                    enable = true,
                    set_jumps = true, -- whether to set jumps in the jumplist
                    goto_next_start = {
                        ["]c"] = { query = "@class.outer", desc = "Next class start" },
                        ["]f"] = { query = "@caller.outer", desc = "Next call start" },
                        ["]i"] = { query = "@conditional.outer", desc = "Next conditional start" },
                        ["]l"] = { query = "@loop.outer", desc = "Next loop start" },
                        ["]m"] = { query = "@function.outer", desc = "Next function/method start" },
                    },
                    goto_next_end = {
                        ["]C"] = { query = "@class.outer", desc = "Next class end" },
                        ["]F"] = { query = "@caller.outer", desc = "Next call end" },
                        ["]I"] = { query = "@conditional.outer", desc = "Next conditional end" },
                        ["]L"] = { query = "@loop.outer", desc = "Next loop end" },
                        ["]M"] = { query = "@function.outer", desc = "Next function/method end" },
                    },
                    goto_previous_start = {
                        ["[c"] = { query = "@class.outer", desc = "Prev class start" },
                        ["[f"] = { query = "@caller.outer", desc = "Prev call start" },
                        ["[i"] = { query = "@conditional.outer", desc = "Prev conditional start" },
                        ["[l"] = { query = "@loop.outer", desc = "Prev loop start" },
                        ["[m"] = { query = "@function.outer", desc = "Prev function/method start" },
                    },
                    goto_previous_end = {
                        ["[C"] = { query = "@class.outer", desc = "Prev class end" },
                        ["[F"] = { query = "@caller.outer", desc = "Prev call end" },
                        ["[I"] = { query = "@conditional.outer", desc = "Prev conditional end" },
                        ["[L"] = { query = "@loop.outer", desc = "Prev loop end" },
                        ["[M"] = { query = "@function.outer", desc = "Prev function/method end" },
                    },
                },
            },
        })
        local ts_repeat_move = require("nvim-treesitter.textobjects.repeatable_move")
        vim.keymap.set({ "n", "o", "x" }, ";", ts_repeat_move.repeat_last_move_next)
        vim.keymap.set({ "n", "o", "x" }, ",", ts_repeat_move.repeat_last_move_previous)

        vim.keymap.set({ "n", "o", "x" }, "f", ts_repeat_move.builtin_f_expr, { expr = true })
        vim.keymap.set({ "n", "o", "x" }, "F", ts_repeat_move.builtin_F_expr, { expr = true })
        vim.keymap.set({ "n", "o", "x" }, "t", ts_repeat_move.builtin_t_expr, { expr = true })
        vim.keymap.set({ "n", "o", "x" }, "T", ts_repeat_move.builtin_T_expr, { expr = true })
    end,
}
