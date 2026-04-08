local bg_dark = "#011423"
local comment_fg = "#79a3a5"

require("tokyonight").setup({
	style = "night",
	transparent = true,
	styles = {
		sidebars = "transparent",
		floats = "transparent",
	},
	on_colors = function(colors)
		colors.comment = comment_fg
		colors.bg = bg_dark
	end,
})

vim.cmd([[colorscheme tokyonight]])

-- Apply harpoon highlight groups after colorscheme is loaded
-- These match tokyonight's styling
vim.api.nvim_set_hl(0, "HarpoonWindow", { link = "NormalNC" })
vim.api.nvim_set_hl(0, "HarpoonBorder", { link = "Border" })
vim.api.nvim_set_hl(0, "HarpoonCurrentFile", { link = "Visual" })
