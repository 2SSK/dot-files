return {
	"stevearc/oil.nvim",
	config = function()
		require("oil").setup({
			columns = { "icon" },
			keymaps = {
				["<C-h>"] = false,
				["<M-h>"] = "actions.select_split",
			},
			view_options = { show_hidden = true },
			float = { border = "rounded" },
			preview = { border = "rounded" },
		})
		vim.keymap.set("n", "-", "<cmd>Oil<CR>", { desc = "Parent directory" })
		vim.keymap.set("n", "<leader>-", require("oil").toggle_float, { desc = "Parent directory (float)" })
	end,
}
