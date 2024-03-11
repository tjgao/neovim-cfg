return {
    "windwp/nvim-autopairs",
    config = function()
        local npairs = require("nvim-autopairs")
        local Rule = require("nvim-autopairs.rule")

        npairs.setup({
            check_ts = true,
            ts_config = {
                lua = { "string" }, -- it will not add a pair on that treesitter node
                javascript = { "template_string" },
                java = false, -- don't check treesitter on java
            },
            disable_filetype = { "TelescopePrompt" },
            -- fast_wrap = {
            --     map = "<c-j>",
            --     pattern = [=[[%'%"%>%]%)%}%,]]=],
            --     chars = { "{", "[", "(", '"', "'" },
            --     end_key = "a",
            --     -- before_key = "h",
            --     -- after_key = "l",
            --     check_comma = true,
            --     cursor_pos_before = true,
            --     keys = "qwertyuiopzxcvbnmsdfghjkl",
            --     manual_position = true,
            --     highlight = "Search",
            --     highlight_grey = "Comment",
            -- },
        })
        local ts_conds = require("nvim-autopairs.ts-conds")
        -- press % => %% only while inside a comment or string
        npairs.add_rules({
            Rule("%", "%", "lua"):with_pair(ts_conds.is_ts_node({ "string", "comment" })),
            Rule("$", "$", "lua"):with_pair(ts_conds.is_not_ts_node({ "function" })),
        })
    end,
}
