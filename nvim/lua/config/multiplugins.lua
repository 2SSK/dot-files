-- Description: Plugins with minimal configuration
return {
	-- Colorscheme
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

	-- Copilot plugin
	{ "github/copilot.vim" },
	--
	-- Vim-move plugin
	{ "matze/vim-move" },
	--
	-- tmux movement
	{ "christoomey/vim-tmux-navigator" },
	--
	-- Colorizer
	{
		"NvChad/nvim-colorizer.lua",
		opts = {
			user_default_options = {
				tailwind = true,
			},
		},
	},

	-- which key
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		init = function()
			vim.o.timeout = true
			vim.o.timeoutlen = 500
		end,
	},

	-- UI enhancement plugin
	{
		"stevearc/dressing.nvim",
		event = "VeryLazy",
	},

	-- Tab bar
	{
		"akinsho/bufferline.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		version = "*",
		opts = {
			options = {
				mode = "tabs",
			},
		},
	},
	-- Icons picker
	{
		"ziontee113/icon-picker.nvim",
		config = function()
			require("icon-picker").setup({ disable_legacy_commands = true })

			local opts = { noremap = true, silent = true }

			vim.keymap.set("n", "<Leader><Leader>i", "<cmd>IconPickerNormal<cr>", opts)
			vim.keymap.set("n", "<Leader><Leader>y", "<cmd>IconPickerYank<cr>", opts) --> Yank the selected icon into register
			-- vim.keymap.set("i", "<C-i>", "<cmd>IconPickerInsert<cr>", opts)
		end,
	},
}
