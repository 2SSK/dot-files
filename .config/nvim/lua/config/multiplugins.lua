-- Description: Plugins with minimal configuration
return {
	-- copilot
	{ "github/copilot.vim" },

	-- Vim-move plugin
	{ "matze/vim-move" },

	-- tmux movement
	{ "christoomey/vim-tmux-navigator" },

	-- UI enhancement plugin
	{
		"stevearc/dressing.nvim",
		event = "VeryLazy",
	},

	-- Cursor smearing
	{
		"sphamba/smear-cursor.nvim",
		opts = {},
	},

	-- 🧘 Zen mode
	{
		"folke/zen-mode.nvim",
	},

	-- screenkey
	{
		"NStefan002/screenkey.nvim",
		lazy = false,
		version = "*", -- or branch = "main", to use the latest commit
	},

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
		end,
	},

	-- Noice plugin
	{
		"folke/noice.nvim",
		event = "VeryLazy",
		opts = {
			routes = {
				{
					filter = { event = "notify", find = "No information available" },
					opts = { skip = true },
				},
			},
			presets = {
				lsp_doc_border = true,
			},
		},
		dependencies = {
			"MunifTanjim/nui.nvim",
			"rcarriga/nvim-notify",
		},
	},

	-- nvim silicon
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
