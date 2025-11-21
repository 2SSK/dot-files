return {
	-- Vim-move plugin
	{ "matze/vim-move" },

	-- UI enhancement plugin
	{
		"stevearc/dressing.nvim",
		event = "VeryLazy",
	},

	-- Tmux movement
	{ "christoomey/vim-tmux-navigator" },

	-- Zen mode
	{ "folke/zen-mode.nvim" },

	-- Colorizer (Highlight Colors)
	{
		"NvChad/nvim-colorizer.lua",
		opts = {
			user_default_options = {
				tailwind = true,
			},
		},
	},

	-- Tab bar
	{
		"akinsho/bufferline.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		version = "*",
		opts = {
			options = {
				diagnostics = "nvim_lsp",
				mode = "tabs",
				show_buffer_close_icons = false,
			},
		},
	},

	-- Silicon (Code SnapShot)
	{
		"michaelrommel/nvim-silicon",
		lazy = true,
		cmd = "Silicon",
		config = function()
			require("silicon").setup({
				font = "JetBrains Mono Nerd Font=34;Noto Color Emoji=34",
				theme = "Dracula",
				background = "#94e2d5",
				window_title = function()
					return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf()), ":t")
				end,
			})
		end,
	},
}
