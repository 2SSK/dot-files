-- The desktop theme's palette as a base16 colourscheme (applied by config/theme.lua)
local theme = require("config.theme").read()
if not theme then
	error("no desktop theme rendered yet (run `theme`)")
end
vim.o.background = theme.background
require("mini.base16").setup({
	palette = theme.palette,
	plugins = { default = true, ["akinsho/bufferline.nvim"] = false }, -- bufferline stays transparent
})

local ui = theme.ui
for group, spec in pairs({
	FloatBorder = { fg = ui.border },
	FloatTitle = { fg = ui.primary, bold = true },
	WinSeparator = { fg = ui.border },
	WhichKey = { fg = ui.primary },
	WhichKeyGroup = { fg = ui.accent },
	WhichKeyDesc = { fg = ui.fg },
	WhichKeySeparator = { fg = ui.fg_muted },
	WhichKeyValue = { fg = ui.fg_muted },
	WhichKeyBorder = { fg = ui.border },
	WhichKeyTitle = { fg = ui.primary, bold = true },
}) do
	vim.api.nvim_set_hl(0, group, spec)
end
vim.g.colors_name = "desktop"
