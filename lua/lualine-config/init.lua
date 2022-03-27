local lualine = require('lualine')
-- local conditions = {
--   buffer_not_empty = function()
--     return vim.fn.empty(vim.fn.expand('%:t')) ~= 1
--   end,
--   hide_in_width = function()
--     return vim.fn.winwidth(0) > 80
--   end,
--   check_git_workspace = function()
--     local filepath = vim.fn.expand('%:p:h')
--     local gitdir = vim.fn.finddir('.git', filepath .. ';')
--     return gitdir and #gitdir > 0 and #gitdir < #filepath
--   end,
-- }

local config = {
    options = {
        icons_enabled = vim.opt.termguicolors,
        theme = 'nord',
--    	component_separators = '',
--    	section_separators = '',
    }
}


-- -- Inserts a component in lualine_c at left section
-- local function ins_left(component)
--     table.insert(config.sections.lualine_c, component)
-- end
-- 
-- -- Inserts a component in lualine_x ot right section
-- local function ins_right(component)
--     table.insert(config.sections.lualine_x, component)
-- end
-- 
-- 
-- -- Add components to right sections
-- ins_right {
--     'o:encoding', -- option component same as &encoding in viml
--     fmt = string.upper, -- I'm not sure why it's upper case either ;)
--     cond = conditions.hide_in_width,
--     -- color = { fg = colors.green, gui = 'bold' },
-- }

lualine.setup(config)

-- print('lualine loaded ...')
