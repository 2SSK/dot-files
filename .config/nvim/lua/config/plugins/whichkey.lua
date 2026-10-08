return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	opts = {
		preset = "helix",
		delay = 300,
		icons = {
			rules = false,
			breadcrumb = " ",
			separator = "󱦰  ",
			group = "󰹍 ",
		},
		plugins = {
			spelling = {
				enabled = false,
			},
		},
		win = {
			border = "rounded",
			height = {
				max = math.huge,
			},
		},
		spec = {
			{
				mode = { "n", "v" },
				{ "<leader>f", group = "Find" },
				{ "<leader>e", group = "Explorer" },
				{ "<leader>c", group = "Code" },
				{ "<leader>x", group = "Diagnostics / lists" },
				{ "<leader>g", group = "Git" },
				{ "<leader>u", group = "UI" },
				{ "<leader>s", group = "Splits / screenshot" },
				{ "<leader>t", group = "Tabs / terminal" },
				{ "<leader>S", group = "Session" },
				{ "<leader>m", group = "Markdown" },
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
			desc = "Buffer keymaps",
		},
	},
}
