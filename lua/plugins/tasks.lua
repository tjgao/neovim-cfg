local task_picker = require("users.tasks.picker")
local task_runtime = require("users.tasks.runtime")

return {
    "stevearc/overseer.nvim",
    enabled = false,
    cmd = {
        "OverseerRun",
        "OverseerToggle",
        "OverseerTaskAction",
        "OverseerInfo",
    },
    keys = {
        { "<leader>tr", task_runtime.run_task_picker_and_remember, desc = "Overseer run task" },
        { "<leader>tt", "<cmd>OverseerToggle<cr>", desc = "Overseer toggle list" },
        { "<leader>ta", "<cmd>OverseerTaskAction<cr>", desc = "Overseer task action" },
        { "<leader>tq", task_runtime.run_recent_task_action, desc = "Run last task or pick" },
        {
            "<leader>tm",
            function()
                task_picker.open_tasks_json_picker()
            end,
            desc = "Manage tasks.json",
        },
        { "<S-F5>", task_runtime.run_recent_task_action, desc = "Run last task or pick" },
        { "<F17>", task_runtime.run_recent_task_action, desc = "Run last task or pick" },
    },
    opts = {
        dap = true,
    },
    config = function(_, opts)
        require("overseer").setup(opts)
    end,
}
