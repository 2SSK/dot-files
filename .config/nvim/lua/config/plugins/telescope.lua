return {
	"nvim-telescope/telescope.nvim",
	tag = "0.1.8",
	dependencies = {
		"nvim-lua/plenary.nvim",
		{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
	},

	config = function()
		local keymap = vim.keymap
		local actions = require("telescope.actions")
		local telescope = require("telescope")
		local builtin = require("telescope.builtin")

		telescope.setup({
			-- Theme
			pickers = {
				find_files = {
					theme = "ivy",
					hidden = true, -- Show hidden files
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

			-- keymaps
			keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "Find files in CWD" }),
			keymap.set("n", "<leader>fr", "<cmd>Telescope oldfiles<cr>", { desc = "Fuzzy fine recent files" }),
			keymap.set("n", "<leader>fs", "<cmd>Telescope live_grep<cr>", { desc = "Find string in CWD" }),
			keymap.set(
				"n",
				"<leader>fc",
				"<cmd>Telescope grep_string<cr>",
				{ desc = "Find string under cursor in CWD" }
			),

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
						["<C-k>"] = actions.move_selection_previous, -- move to prev result
						["<C-j>"] = actions.move_selection_next, -- move to next result
					},
				},
			},

			-- keymap to fuzzy search in current buffer
			vim.keymap.set("n", "<leader>/", function()
				-- You can pass additional configuration to Telescope to change the theme, layout, etc.
				builtin.current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
					winblend = 10,
					previewer = false,
				}))
			end, { desc = "[/] Fuzzily search in current buffer" }),

			-- Keybind to open config files
			keymap.set("n", "<leader>en", function()
				require("telescope.builtin").find_files({
					cwd = vim.fn.stdpath("config"),
				})
			end),
		})

		require("config.telescope.multigrep").setup()
	end,
}
