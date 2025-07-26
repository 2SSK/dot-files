-- return {
-- 	"catppuccin/nvim",
-- 	name = "catppuccin",
-- 	priority = 1000,
-- 	config = function()
-- 		local comment_fg = "#79a3a5"
-- 		require("catppuccin").setup({
-- 			flavour = "mocha",
-- 			transparent_background = false,
-- 			styles = {
-- 				sidebars = "transparent",
-- 				floats = "transparent",
-- 			},
-- 			custom_highlights = function(colors)
-- 				return {
-- 					Comment = { fg = comment_fg },
-- 					-- Add more custom highlights here if needed
-- 				}
-- 			end,
-- 		})
-- 		vim.cmd([[colorscheme catppuccin]])
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
