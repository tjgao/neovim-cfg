local group = vim.api.nvim_create_augroup("Obsidian", {})

vim.api.nvim_create_autocmd("FileType", {
    pattern = "markdown",
    group = group,
    callback = function(ctx)
        vim.keymap.set("n", "gf", function()
            if require("obsidian").util.cursor_on_markdown_link() then
                return "<cmd>ObsidianFollowLink<CR>"
            end
            return "gf"
        end, { noremap = false, expr = true, buffer = ctx.buf })
    end,
})

local gen_random_str = function(len)
    local id = ""
    for _ = 1, len do
        id = id .. string.char(math.random(97, 122))
    end
    return id
end

local gen_id = function()
    return tostring(os.date("%Y-%m-%d_%H:%M:%S", os.time())) .. "-" .. gen_random_str(6)
end

return {
    "epwalsh/obsidian.nvim",
    version = "*", -- recommended, use latest release instead of latest commit
    lazy = false,
    ft = "markdown",
    -- Replace the above line with this if you only want to load obsidian.nvim for markdown files in your vault:
    -- event = {
    --   -- If you want to use the home shortcut '~' here you need to call 'vim.fn.expand'.
    --   -- E.g. "BufReadPre " .. vim.fn.expand "~" .. "/my-vault/*.md"
    --   -- refer to `:h file-pattern` for more examples
    --   "BufReadPre path/to/my-vault/*.md",
    --   "BufNewFile path/to/my-vault/*.md",
    -- },
    dependencies = {
        -- Required.
        "nvim-lua/plenary.nvim",
        "hrsh7th/nvim-cmp",
    },
    config = function()
        require("obsidian").setup({
            workspaces = {
                {
                    name = "DigitalBrain",
                    path = "~/Documents/Tiejun-Obsidian",
                },
            },
            -- where new notes go, will be moved to other subdir after review
            notes_subdir = "inbox",
            mappings = {
                -- Toggle check-boxes.
                ["<leader>ch"] = {
                    action = function()
                        return require("obsidian").util.toggle_checkbox()
                    end,
                    opts = { buffer = true },
                },
                -- Smart action depending on context, either follow link or toggle checkbox.
                ["<cr>"] = {
                    action = function()
                        return require("obsidian").util.smart_action()
                    end,
                    opts = { buffer = true, expr = true },
                },
            },
            -- Optional, for templates (see below).
            templates = {
                folder = "templates",
                date_format = "%Y-%m-%d",
                time_format = "%H:%M",
                -- A map for custom variables, the key should be the variable and the value a function
                substitutions = {},
            },
            -- Optional, customize how note file names are generated given the ID, target directory, and title.
            -- @param spec { id: string, dir: obsidian.Path, title: string|? }
            -- @return string|obsidian.Path The full path to the new note.
            note_path_func = function(spec)
                -- This is equivalent to the default behavior.
                local fn = ""
                if spec.title then
                    fn = spec.title:gsub(" ", "-"):gsub("[&*$!@^#?,.%%()%[%]+'\"]", ""):lower()
                    fn = fn .. "_" .. gen_random_str(4)
                else
                    fn = gen_id()
                end
                local path = spec.dir / fn
                return path:with_suffix(".md")
            end,
            ---@diagnostic disable-next-line: unused-local
            note_id_func = function(title)
                return gen_id()
            end,
            note_frontmatter_func = function(note)
                -- Add the title of the note as an alias.
                -- if note.title then
                --     note:add_alias(note.title)
                -- end
                local id = note.id
                if note.title then
                    id = gen_id()
                end
                local title = " "
                if note.title then
                    title = note.title
                end
                local out = {
                    id = id,
                    title = title,
                    aliases = {},
                    tags = note.tags,
                    createdAt = tostring(os.date("%Y-%m-%d %H:%M:%S", os.time())),
                }

                -- `note.metadata` contains any manually added fields in the frontmatter.
                -- So here we just make sure those fields are kept in the frontmatter.
                if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
                    for k, v in pairs(note.metadata) do
                        out[k] = v
                    end
                end

                return out
            end,
        })
    end,
}
