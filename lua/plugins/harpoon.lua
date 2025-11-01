return {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
        local harpoon = require("harpoon")
        harpoon.setup({
            settings = {
                save_on_toggle = true,
                sync_on_ui_close = true,
            },
        })
        vim.keymap.set("n", "<leader>ha", function()
            -- we remove it first and then append it back
            -- this allows us to update the file row/col location
            harpoon:list():remove()
            harpoon:list():add()
        end, { desc = "Add current file [Harpoon]" })
        vim.keymap.set("n", "<leader>hm", function()
            harpoon.ui:toggle_quick_menu(harpoon:list())
        end, { desc = "Toggle quick menu [Harpoon]" })
        vim.keymap.set("n", "<A-1>", function()
            harpoon:list():select(1)
        end)
        vim.keymap.set("n", "<A-2>", function()
            harpoon:list():select(2)
        end)
        vim.keymap.set("n", "<A-3>", function()
            harpoon:list():select(3)
        end)
        vim.keymap.set("n", "<A-4>", function()
            harpoon:list():select(4)
        end)
        vim.keymap.set("n", "<A-j>", function()
            harpoon:list():prev({ ui_nav_wrap = true })
        end)
        vim.keymap.set("n", "<A-k>", function()
            harpoon:list():next({ ui_nav_wrap = true })
        end)
    end,
}
