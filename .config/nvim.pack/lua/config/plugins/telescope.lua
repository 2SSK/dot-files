local actions = require("telescope.actions")
local telescope = require("telescope")
local builtin = require("telescope.builtin")

telescope.setup({
	pickers = {
		find_files = {
			theme = "ivy",
			hidden = true,
			no_ignore = false,
			no_ignore_parent = false,
		},
		oldfiles = {
			theme = "ivy",
		},
		live_grep = {
			theme = "ivy",
		},
		grep_string = {
			theme = "ivy",
		},
	},
	defaults = {
		file_ignore_patterns = {
			"node_modules",
			".git",
			"dist",
			"build",
			"vendor",
			"%.lock",
			"%.png",
			"%.jpg",
			"%.jpeg",
			"%.gif",
			"%.svg",
		},
		path_display = { "smart" },
		mappings = {
			i = {
				["<C-k>"] = actions.move_selection_previous,
				["<C-j>"] = actions.move_selection_next,
			},
		},
	},
})

-- Fix: Use explicit vim.keymap.set instead of keymap in setup
-- Find files in CWD
vim.keymap.set("n", "<leader>ff", function()
	builtin.find_files()
end, { desc = "Find files in CWD" })

-- Fuzzy find recent files
vim.keymap.set("n", "<leader>fr", function()
	builtin.oldfiles()
end, { desc = "Fuzzy find recent files" })

-- Find string in CWD
vim.keymap.set("n", "<leader>fs", function()
	builtin.live_grep()
end, { desc = "Find string in CWD" })

-- Find string under cursor
vim.keymap.set("n", "<leader>fc", function()
	builtin.grep_string()
end, { desc = "Find string under cursor in CWD" })

-- Current buffer fuzzy find
vim.keymap.set("n", "<leader>/", function()
	builtin.current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
		winblend = 10,
		previewer = false,
	}))
end, { desc = "[/] Fuzzily search in current buffer" })

-- Open Neovim config files
vim.keymap.set("n", "<leader>en", function()
	builtin.find_files({
		cwd = vim.fn.stdpath("config"),
	})
end, { desc = "Open Neovim config files" })

-- Open Notes folder
vim.keymap.set("n", "<leader>on", function()
	builtin.find_files({
		cwd = "~/SSK-Vault",
	})
end, { desc = "Open Notes folder" })

-- Setup multigrep
require("config.telescope.multigrep").setup()
-- Silent - no print notifications