return {
    "folke/trouble.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
        -- your configuration comes here
        -- or leave it empty to use the default settings
        -- refer to the configuration section below
    },
    config = function()
        local trouble = require("trouble")
        trouble.setup()
        vim.api.nvim_create_user_command("Tt", function()
            vim.g.last_trouble_mode = "telescope"
            vim.cmd("Trouble telescope toggle focus=true")
        end, { desc = "Toggle trouble telescope" })
        vim.api.nvim_create_user_command("Ttf", function()
            vim.g.last_trouble_mode = "telescope_files"
            vim.cmd("Trouble telescope_files toggle focus=true")
        end, { desc = "Toggle trouble telescope files" })
        vim.api.nvim_create_user_command("Tq", function()
            vim.g.last_trouble_mode = "qflist"
            vim.cmd("Trouble qflist toggle focus=true")
        end, { desc = "Toggle trouble qflist" })
        vim.api.nvim_create_user_command("Tl", function()
            vim.g.last_trouble_mode = "loclist"
            vim.cmd("Trouble loclist toggle focus=true")
        end, { desc = "Toggle trouble loclist" })
        vim.api.nvim_create_user_command("Td", function()
            vim.g.last_trouble_mode = "diagnostics"
            vim.cmd("Trouble diagnostics toggle focus=true")
        end, { desc = "Toggle trouble diagnostics" })

        vim.keymap.set({ "n", "v" }, "<C-q>", function()
            local last_trouble_mode = vim.g.last_trouble_mode or "telescope"
            vim.cmd("Trouble " .. last_trouble_mode .. " toggle focus=true")
        end, { silent = true })

        -- local group = vim.api.nvim_create_augroup("troubleGroup", {})
        -- autocmd allows us to update qflist with the modified content in trouble
        -- vim.api.nvim_create_autocmd("FileType", {
        --     pattern = "trouble",
        --     group = group,
        --     callback = function()
        --         vim.api.nvim_buf_create_user_command(0, "Save", function()
        --             if not (trouble.is_open("qflist") or trouble.isopen("loclist")) then
        --                 return
        --             end
        --             local mode = trouble.is_open("qflist") and "qflist" or "loclist"
        --             local items = trouble.get_items(mode)
        --             vim.print(items)
        --             local qf = vim.fn.getqflist({ all = true })
        --             vim.print(qf)
        --         end, { desc = "Update qflist/loclist" })
        --     end,
        -- })
    end,
}
