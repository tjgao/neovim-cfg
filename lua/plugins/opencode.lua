return {
    "sudo-tee/opencode.nvim",
    config = function()
        local function format_prompt_lines(lines)
            local out = {}
            local paragraph = {}

            local function flush_paragraph()
                if #paragraph == 0 then
                    return
                end

                local merged = paragraph[1]
                for i = 2, #paragraph do
                    local next_line = paragraph[i]
                    local prev_ends_with_space = merged:match("%s$") ~= nil
                    local next_starts_with_space = next_line:match("^%s") ~= nil
                    if prev_ends_with_space or next_starts_with_space then
                        merged = merged .. next_line
                    else
                        merged = merged .. " " .. next_line
                    end
                end

                table.insert(out, merged)
                paragraph = {}
            end

            for _, line in ipairs(lines) do
                if line == "" then
                    flush_paragraph()
                    table.insert(out, "")
                else
                    table.insert(paragraph, line)
                end
            end

            flush_paragraph()
            return out
        end

        local function submit_with_formatting()
            local state = require("opencode.state")
            local windows = state.windows
            if not windows or not windows.input_buf or not vim.api.nvim_buf_is_valid(windows.input_buf) then
                return require("opencode.api").submit_input_prompt()
            end

            local lines = vim.api.nvim_buf_get_lines(windows.input_buf, 0, -1, false)
            local formatted = format_prompt_lines(lines)
            vim.api.nvim_buf_set_lines(windows.input_buf, 0, -1, false, formatted)

            return require("opencode.api").submit_input_prompt()
        end

        require("opencode").setup({
            keymap = {
                editor = {
                    ["<C-.>"] = { "toggle" },
                },
                input_window = {
                    ["<S-cr>"] = {
                        submit_with_formatting,
                        mode = { "n", "i" },
                        desc = "Format + submit prompt",
                    },
                },
            },
        })
    end,
    dependencies = {
        "nvim-lua/plenary.nvim",
        {
            "MeanderingProgrammer/render-markdown.nvim",
            opts = {
                anti_conceal = { enabled = false },
                file_types = { "markdown", "opencode_output" },
            },
            ft = { "markdown", "Avante", "copilot-chat", "opencode_output" },
        },
        -- Optional, for file mentions picker, pick only one
        "folke/snacks.nvim",
        -- 'nvim-telescope/telescope.nvim',
        -- 'ibhagwan/fzf-lua',
        -- 'nvim_mini/mini.nvim',
    },
}
