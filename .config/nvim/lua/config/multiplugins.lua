return {
	-- Vim-move plugin
	{ "matze/vim-move" },

	-- Smear-Cursor
	{
		"sphamba/smear-cursor.nvim",
		opts = { -- Default  Range
			stiffness = 0.8, -- 0.6      [0, 1]
			trailing_stiffness = 0.5, -- 0.4      [0, 1]
			stiffness_insert_mode = 0.7, -- 0.5      [0, 1]
			trailing_stiffness_insert_mode = 0.7, -- 0.5      [0, 1]
			damping = 0.8, -- 0.65     [0, 1]
			damping_insert_mode = 0.8, -- 0.7      [0, 1]
			distance_stop_animating = 0.5, -- 0.1      > 0
		},
	},

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

	-- Which key
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
	{
		{
			"saecki/crates.nvim",
			ft = { "rust", "toml" },
			config = function(_, opts)
				local crates = require("crates")
				crates.setup(opts)
				crates.show()
			end,
		},
	},
}
