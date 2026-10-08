-- Colourschemes for the desktop theme families (applied by config/theme.lua). All lazy:
-- lazy.nvim loads one when it is applied with :colorscheme.
return {
	{
		"folke/tokyonight.nvim",
		lazy = true,
		opts = {
			on_colors = function(colors)
				colors.comment = "#79a3a5" -- brighter comments
			end,
		},
	},
	{ "catppuccin/nvim", name = "catppuccin", lazy = true },
	{ "ellisonleao/gruvbox.nvim", lazy = true },
	{ "rose-pine/neovim", name = "rose-pine", lazy = true },
	{
		"alexxGmZ/e-ink.nvim",
		lazy = true,
		config = function()
			require("e-ink").setup()
		end,
	},
}
