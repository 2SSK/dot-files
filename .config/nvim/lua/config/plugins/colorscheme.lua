return {
	-- Theme Switcher
	{
		"andrew-george/telescope-themes",
		config = function()
			require("telescope").load_extension("themes")
		end,
	},
	-- Themes
	{
		"folke/tokyonight.nvim",
		priority = 1000,
		config = function()
			-- Custom comments color
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
			vim.cmd.colorscheme("tokyonight")
		end,
	},
	-- Gruvbox theme
	{
		"ellisonleao/gruvbox.nvim",
		priority = 1000,
		config = function()
			require("gruvbox").setup({
				style = "dark",
				dim_inactive = false,
				transparent_mode = true,
				styles = {
					sidebars = "transparent",
					floats = "transparent",
				},
			})
			vim.cmd.colorscheme("gruvbox")
		end,
	},
	-- Rose pine
	{
		"rose-pine/neovim",
		name = "rose-pine",
		config = function()
			require("rose-pine").setup({
				variant = "main",
				styles = {
					transparency = true,
				},
			})

			vim.cmd("colorscheme rose-pine")
		end,
	},
	-- Catppuccino theme
	{
		"catppuccin/nvim",
		name = "catppuccin",
		priority = 1000,
		config = function()
			require("catppuccin").setup({
				flavour = "mocha",
				transparent_background = true,
			})
		end,
	},
}
