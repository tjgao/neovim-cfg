return {
    dir = "/home/tiejun/code/github/flyout.nvim",
    name = "flyout",
    -- "tjgao/flyout.nvim",
    config = function()
        require("flyout").setup({
            ui = {
                task_list_width = "50%",
                task_list_height = "25%",
                preview_height = "40%",
            },
            notifications = {
                start = false,
                ["end"] = false,
                progress = {
                    enabled = true,
                    interval_ms = 120,
                    frames = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" },
                },
            },
        })
    end,
}
