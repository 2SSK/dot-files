-- return {
-- 	"shaunsingh/nord.nvim",
-- 	lazy = false,
-- 	priority = 1000,
-- 	config = function()
-- 		-- Example config in lua
-- 		vim.g.nord_contrast = true
-- 		vim.g.nord_borders = false
-- 		vim.g.nord_disable_background = true
-- 		vim.g.set_cursorline_transparent = false
-- 		vim.g.nord_italic = false
-- 		vim.g.nord_enable_sidebar_background = false
-- 		vim.g.nord_uniform_diff_background = true
-- 		vim.g.nord_bold = false -- enables/disables bold
--
-- 		-- Load the colorscheme
-- 		require("nord").set()
--
-- 		-- Function to set menu borders to transparent
-- 		local set_menu_border_transparency = function()
-- 			vim.api.nvim_set_hl(0, "NormalFloat", { bg = "NONE", fg = "NONE" })
-- 			vim.api.nvim_set_hl(0, "FloatBorder", { bg = "NONE", fg = "NONE" })
-- 		end
--
-- 		-- Execute the function once after loading the colorscheme
-- 		set_menu_border_transparency()
--
-- 		local bg_transparent = true
--
-- 		-- Toggle background transparency
-- 		local toggle_transparency = function()
-- 			bg_transparent = not bg_transparent
-- 			vim.g.nord_disable_background = bg_transparent
-- 			vim.cmd([[colorscheme nord]])
-- 			-- set_menu_border_transparency()
-- 		end
--
-- 		vim.keymap.set("n", "<leader>bg", toggle_transparency, { noremap = true, silent = true })
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
