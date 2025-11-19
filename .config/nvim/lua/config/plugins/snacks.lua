return {
	"folke/snacks.nvim",
	opts = {
		picker = {
			reverse = false,
			sources = {
				files = {
					layout = { preview = false },
					hidden = true,
				},
				-- explorer (snacks picker)
				explorer = {
					hidden = true,
					layout = { preset = "sidebar", layout = { position = "right", width = 50 } },
					git_status = true,
				},
			},
		},
	},

	keys = {
		{
			"<leader>ee",
			function()
				Snacks.explorer()
			end,
			desc = "File Explorer",
		},
		{
			"<leader>ef",
			function()
				Snacks.picker.explorer({ cwd = vim.fn.getcwd() })
			end,
			desc = "Explorer (cwd)",
		},

		{
			"<leader>gi",
			function()
				Snacks.picker.gh_issue()
			end,
			desc = "GitHub Issues (open)",
		},
		{
			"<leader>gI",
			function()
				Snacks.picker.gh_issue({ state = "all" })
			end,
			desc = "GitHub Issues (all)",
		},
		{
			"<leader>gp",
			function()
				Snacks.picker.gh_pr()
			end,
			desc = "GitHub Pull Requests (open)",
		},
		{
			"<leader>gP",
			function()
				Snacks.picker.gh_pr({ state = "all" })
			end,
			desc = "GitHub Pull Requests (all)",
		},
	},
}
