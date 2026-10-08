-- snacks.nvim: picker (files, grep, LSP, diagnostics), dashboard, explorer, notifications,
-- input prompts, indent guides, zen mode, lazygit and git blame in one plugin.
return {
	"folke/snacks.nvim",
	priority = 1000,
	lazy = false,
	opts = {
		dashboard = { enabled = true },
		explorer = { enabled = true },
		indent = { enabled = true },
		input = { enabled = true },
		notifier = { enabled = true },
		lazygit = { enabled = true },
		zen = { enabled = true },
		picker = {
			reverse = false,
			layout = { preset = "ivy", ivy = { style = "vim" } },
			sources = {
				files = {
					layout = { preview = false },
					hidden = true,
					ignored = true, -- show files ignored by .gitignore
					exclude = { "node_modules", ".git", "dist", "build", "vendor", "*.lock", "*.png", "*.jpg", "*.jpeg", "*.gif", "*.svg" },
				},
				explorer = {
					hidden = true,
					ignored = true,
					layout = { preset = "sidebar", layout = { position = "right", width = 50 } },
					git_status = true,
				},
			},
		},
		styles = { notification = { wo = { wrap = true } } },
	},
	keys = {
		-- Find
		{ "<leader>ff", function() Snacks.picker.files() end, desc = "Find files in CWD" },
		{ "<leader>fr", function() Snacks.picker.recent() end, desc = "Recent files" },
		{ "<leader>fs", function() Snacks.picker.grep() end, desc = "Find string in CWD (type -- -g *.lua to filter)" },
		{ "<leader>fg", function() Snacks.picker.grep() end, desc = "Grep (pattern -- -g glob)" },
		{ "<leader>fc", function() Snacks.picker.grep_word() end, desc = "Find string under cursor", mode = { "n", "x" } },
		{ "<leader>fb", function() Snacks.picker.buffers() end, desc = "Buffers" },
		{ "<leader>ft", function() Snacks.picker.grep({ search = "\\b(TODO|FIXME|HACK|NOTE|WARN|PERF)\\b", regex = true, live = false }) end, desc = "Todo comments" },
		{ "<leader>fh", function() Snacks.picker.help() end, desc = "Help pages" },
		{ "<leader>/", function() Snacks.picker.lines() end, desc = "Fuzzy search in current buffer" },
		{ "<leader>en", function() Snacks.picker.files({ cwd = vim.fn.stdpath("config") }) end, desc = "Neovim config files" },
		-- Explorer
		{ "<leader>ee", function() Snacks.explorer() end, desc = "File explorer" },
		{ "<leader>ef", function() Snacks.picker.explorer({ cwd = vim.fn.getcwd() }) end, desc = "Explorer (cwd)" },
		-- Diagnostics and symbols (were Trouble)
		{ "<leader>xx", function() Snacks.picker.diagnostics() end, desc = "Diagnostics" },
		{ "<leader>xX", function() Snacks.picker.diagnostics_buffer() end, desc = "Buffer diagnostics" },
		{ "<leader>cs", function() Snacks.picker.lsp_symbols() end, desc = "Document symbols" },
		{ "<leader>xL", function() Snacks.picker.loclist() end, desc = "Location list" },
		{ "<leader>xQ", function() Snacks.picker.qflist() end, desc = "Quickfix list" },
		-- Git (lazygit replaces fugitive)
		{ "<leader>gs", function() Snacks.lazygit() end, desc = "Lazygit" },
		{ "<leader>gl", function() Snacks.lazygit.log() end, desc = "Git log (lazygit)" },
		{ "<leader>gf", function() Snacks.lazygit.log_file() end, desc = "File history (lazygit)" },
		{ "<leader>gb", function() Snacks.git.blame_line() end, desc = "Blame line" },
		{ "<leader>gi", function() Snacks.picker.gh_issue() end, desc = "GitHub issues (open)" },
		{ "<leader>gI", function() Snacks.picker.gh_issue({ state = "all" }) end, desc = "GitHub issues (all)" },
		{ "<leader>gp", function() Snacks.picker.gh_pr() end, desc = "GitHub pull requests (open)" },
		{ "<leader>gP", function() Snacks.picker.gh_pr({ state = "all" }) end, desc = "GitHub pull requests (all)" },
		-- UI
		{ "<leader>uz", function() Snacks.zen() end, desc = "Zen mode" },
		{ "<leader>un", function() Snacks.notifier.show_history() end, desc = "Notification history" },
	},
}
