-- return {
-- 	"AlexvZyl/nordic.nvim",
-- 	lazy = false,
-- 	priority = 1000,
-- 	config = function()
-- 		require("nordic").setup({
-- 			transparent = {
-- 				bg = true,
-- 				float = true,
-- 			},
-- 		})
-- 		require("nordic").load()
-- 	end,
-- }

return {
	"folke/tokyonight.nvim",
	name = "tokyonight",
	priority = 1000,
	config = function()
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
			end,
		})
		vim.cmd([[colorscheme tokyonight]])
	end,
}
