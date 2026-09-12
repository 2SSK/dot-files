return {
	{
		"epwalsh/obsidian.nvim",
		version = "*",
		event = "VeryLazy",
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
		opts = {
			dir = "~/Work-Vault",
			notes_subdir = "03-Work",
			daily_notes = {
				folder = "01-Daily",
				date_format = "%Y/%m/%d",
				template = "04-Templates/Daily.md",
			},
			templates = {
				subdir = "04-Templates",
			},
			workspaces = {
				{ name = "work", path = "~/Work-Vault" },
			},
			ui = {
				enable = false,
			},
			completion = {
				nvim_cmp = false,
				min_chars = 2,
			},
		},
		keys = {
			{ "<leader>oo", "<cmd>ObsidianQuickSwitch<cr>", desc = "Obsidian: quick switch" },
			{ "<leader>os", "<cmd>ObsidianSearch<cr>", desc = "Obsidian: search notes" },
			{ "<leader>on", "<cmd>ObsidianNew<cr>", desc = "Obsidian: new note" },
			{ "<leader>ob", "<cmd>ObsidianBacklinks<cr>", desc = "Obsidian: backlinks" },
			{ "<leader>od", "<cmd>ObsidianToday<cr>", desc = "Obsidian: today's note" },
			{ "<leader>op", "<cmd>ObsidianOpen<cr>", desc = "Obsidian: open in app" },
		},
	},
}
