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
vim.g.colors_name = "desktop"
