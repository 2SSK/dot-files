return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	opts = {
		preset = "helix",
		delay = 300,
		icons = {
			rules = false,
			breadcrumb = " ", -- symbol used in the command line area that shows your active key combo
			separator = "󱦰  ", -- symbol used between a key and it's label
			group = "󰹍 ", -- symbol prepended to a group
		},
		plugins = {
			spelling = {
				enabled = false,
			},
		},
		win = {
			height = {
				max = math.huge,
			},
		},
		spec = {
			{
				mode = { "n", "v" },
				{ "<leader>f", group = "Find" },
				{ "<leader>g", group = "Git" },
				{ "<leader>e", group = "Explorer / config" },
				{ "<leader>c", group = "Code" },
				{ "<leader>x", group = "Diagnostics / lists" },
				{ "<leader>u", group = "UI" },
				{ "<leader>w", group = "Session" },
				{ "<leader>d", group = "Diff" },
				{ "[", group = "prev" },
				{ "]", group = "next" },
				{ "g", group = "goto" },
			},
		},
	},
	keys = {
		{
			"<leader>?",
			function()
				require("which-key").show({ global = false })
			end,
			desc = "Buffer Local Keymaps (which-key)",
		},
	},
}
