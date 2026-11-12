return {
	"folke/snacks.nvim",
	priority = 1000,
	lazy = false,
	opts = {
		dashboard = { enabled = true },
		explorer = { enabled = true },
		input = { enabled = true },
		notifier = { enabled = true },
		zen = { enabled = true },
		picker = {
			reverse = false,
			layout = { preset = "ivy", layout = { height = 0.7 } },
			sources = {
				files = {
					layout = { preview = false },
					hidden = true,
					ignored = true,
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
		{ "<leader>ff", function() Snacks.picker.files() end, desc = "Files" },
		{ "<leader>fr", function() Snacks.picker.recent() end, desc = "Recent files" },
		{ "<leader>fs", function() Snacks.picker.grep() end, desc = "Grep (pattern -- -g glob)" },
		{ "<leader>fc", function() Snacks.picker.grep_word() end, desc = "Grep word under cursor", mode = { "n", "x" } },
		{ "<leader>fb", function() Snacks.picker.buffers() end, desc = "Buffers" },
		{ "<leader>ft", function() Snacks.picker.grep({ search = "\\b(TODO|FIXME|HACK|NOTE|WARN|PERF)\\b", regex = true, live = false }) end, desc = "Todo comments" },
		{ "<leader>fh", function() Snacks.picker.help() end, desc = "Help pages" },
		{ "<leader>/", function() Snacks.picker.lines() end, desc = "Search in buffer" },
		{ "<leader>ee", function() Snacks.explorer() end, desc = "File explorer" },
		{ "<leader>en", function() Snacks.picker.files({ cwd = vim.fn.stdpath("config") }) end, desc = "Neovim config" },
		{ "<leader>xx", function() Snacks.picker.diagnostics() end, desc = "Diagnostics" },
		{ "<leader>xX", function() Snacks.picker.diagnostics_buffer() end, desc = "Buffer diagnostics" },
		{ "<leader>xL", function() Snacks.picker.loclist() end, desc = "Location list" },
		{ "<leader>xQ", function() Snacks.picker.qflist() end, desc = "Quickfix list" },
		{ "<leader>cs", function() Snacks.picker.lsp_symbols() end, desc = "Symbols" },
		{ "<leader>gs", function() Snacks.picker.git_status() end, desc = "Status" },
		{ "<leader>gl", function() Snacks.picker.git_log() end, desc = "Log" },
		{ "<leader>gf", function() Snacks.picker.git_log_file() end, desc = "File history" },
		{ "<leader>gb", function() Snacks.git.blame_line() end, desc = "Blame line" },
		{ "<leader>gi", function() Snacks.picker.gh_issue() end, desc = "GitHub issues (open)" },
		{ "<leader>gI", function() Snacks.picker.gh_issue({ state = "all" }) end, desc = "GitHub issues (all)" },
		{ "<leader>gp", function() Snacks.picker.gh_pr() end, desc = "GitHub pull requests (open)" },
		{ "<leader>gP", function() Snacks.picker.gh_pr({ state = "all" }) end, desc = "GitHub pull requests (all)" },
		{ "<leader>uz", function() Snacks.zen() end, desc = "Zen mode" },
		{ "<Esc>", function() Snacks.notifier.hide() vim.cmd.nohlsearch() return "<Esc>" end, expr = true, desc = "Clear search and notifications" },
		{ "<leader>un", function() Snacks.notifier.hide() end, desc = "Dismiss notifications" },
		{ "<leader>uh", function() Snacks.notifier.show_history() end, desc = "Notification history" },
	},
	config = function(_, opts)
		require("snacks").setup(opts)
		-- nvim 0.12 refuses a window size that isn't a whole number, and snacks can make one: the
		-- code action menu's list is min(items, lines * 0.8 - 10) high, so 20 actions in a 33-line
		-- window asked for 18.4 rows ("Invalid 'height': Number is not integral"). Whole cells, always.
		local Win = require("snacks.win")
		local dim = Win.dim
		Win.dim = function(self, parent)
			local d = dim(self, parent)
			for _, k in ipairs({ "height", "width", "row", "col" }) do
				d[k] = math.floor(d[k])
			end
			return d
		end
	end,
}
