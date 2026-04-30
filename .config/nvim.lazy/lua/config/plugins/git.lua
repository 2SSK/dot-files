return {
	{
		"tpope/vim-fugitive",
		-- Configure Fugitive keybindings
		config = function()
			-- General Fugitive keybindings
			vim.keymap.set("n", "<leader>gs", ":Git<CR>", { desc = "Git status" })
			vim.keymap.set("n", "<leader>gc", ":Git commit<CR>", { desc = "Git commit" })
			vim.keymap.set("n", "<leader>gp", ":Git push<CR>", { desc = "Git push" })
			vim.keymap.set("n", "<leader>gP", ":Git pull<CR>", { desc = "Git pull" })
			vim.keymap.set("n", "<leader>gb", ":Git blame<CR>", { desc = "Git blame" })
			vim.keymap.set("n", "<leader>gd", ":Gdiffsplit<CR>", { desc = "Git diff split" })
			vim.keymap.set("n", "<leader>gD", ":Gvdiffsplit!<CR>", { desc = "Git vertical diff split (3-way)" })
			vim.keymap.set("n", "<leader>dt", function()
				-- Toggle between file and diff view
				if vim.wo.diff then
					vim.cmd("diffoff")
				else
					vim.cmd("Git diff --no-ext-diff")
				end
			end, { desc = "Toggle diff (fugitive)" })

			-- Git conflict resolution keybindings
			vim.keymap.set("n", "]c", function()
				vim.cmd("normal! ]c")
			end, { desc = "Jump to next conflict" })

			vim.keymap.set("n", "[c", function()
				vim.cmd("normal! [c")
			end, { desc = "Jump to previous conflict" })

			-- Quick conflict resolution (use in merge conflict buffer)
			-- 'gu' = get ours (local/left side)
			-- 'gh' = get theirs (remote/right side)
			vim.keymap.set("n", "gu", ":diffget //2<CR>", { desc = "Get ours (local)" })
			vim.keymap.set("n", "gh", ":diffget //3<CR>", { desc = "Get theirs (remote)" })
			vim.keymap.set("n", "gf", ":diffget //2<CR>", { desc = "Get ours (local) - alt" })
			vim.keymap.set("n", "gj", ":diffget //3<CR>", { desc = "Get theirs (remote) - alt" })

			-- Visual mode conflict resolution
			vim.keymap.set("x", "gu", ":diffget //2<CR>", { desc = "Get ours (local) visual" })
			vim.keymap.set("x", "gh", ":diffget //3<CR>", { desc = "Get theirs (remote) visual" })

			-- Diff navigation
			vim.keymap.set("n", "do", ":diffget<CR>", { desc = "Diff obtain (get from current)" })
			vim.keymap.set("n", "dp", ":diffput<CR>", { desc = "Diff put (send to other)" })

			-- Fugitive status window keybindings (auto-configured when entering .git index buffer)
			vim.api.nvim_create_autocmd("FileType", {
				pattern = "fugitive",
				callback = function()
					-- Common fugitive status mappings
					vim.keymap.set("n", "s", ":Git add %<CR>", { buffer = true, desc = "Stage file" })
					vim.keymap.set("n", "u", ":Git reset %<CR>", { buffer = true, desc = "Unstage file" })
					vim.keymap.set("n", "cc", ":Git commit<CR>", { buffer = true, desc = "Commit" })
					vim.keymap.set("n", "ca", ":Git commit --amend<CR>", { buffer = true, desc = "Amend commit" })
					vim.keymap.set("n", "dv", ":Gdiffsplit!<CR>", { buffer = true, desc = "Diff vertical split" })
					vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = true, desc = "Close window" })
				end,
			})

			-- Show remaining conflicts count
			vim.cmd([[
				function! ConflictStats()
					let l:conflict_pattern = '^<<<<<<< '
					let l:conflicts = search(l:conflict_pattern, 'nw')
					if l:conflicts == 0
						echohl MoreMsg
						echo "✓ No remaining conflicts"
						echohl None
					else
						echohl WarningMsg
						echo "Remaining conflicts: " . l:conflicts
						echohl None
					endif
				endfunction
			]])
			vim.keymap.set("n", "<leader>gC", ":call ConflictStats()<CR>", { desc = "Show conflict count" })
		end,
	},
	{
		"f-person/git-blame.nvim",
		event = "VeryLazy",
		opts = {
			enabled = true, -- if you want to enable the plugin
			message_template = " <summary> • <date> • <author> • <<sha>>", -- template for the blame message, check the Message template section for more options
			date_format = "%m-%d-%Y %H:%M:%S", -- template for the date, check Date format section for more options
			virtual_text_column = 1, -- virtual text start column, check Start virtual text at column section for more options
		},
	},
}
