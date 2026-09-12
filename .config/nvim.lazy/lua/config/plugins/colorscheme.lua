return {
	"folke/tokyonight.nvim",
	name = "tokyonight",
	priority = 1000,
	config = function()
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
	end,
}
