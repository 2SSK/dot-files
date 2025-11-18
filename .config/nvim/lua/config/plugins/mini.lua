return {
	"echasnovski/mini.nvim",
	version = false, -- Always use the latest version
	config = function()
		-- Mini Indentscope
		require("mini.indentscope").setup({
			draw = {
				delay = 0,
				animation = require("mini.indentscope").gen_animation.none(),
			},
		})
		-- Mini a/i Textobjects
		require("mini.ai").setup()

		-- Mini Pairs
		require("mini.pairs").setup()

		-- Mini Surround
		require("mini.surround").setup()

		-- Mini git diff
		require("mini.diff").setup()

		-- Mini Files
		require("mini.files").setup({
			mappings = {
				synchronize = "s",
			},
		})

		-- Keybindings
		vim.api.nvim_set_keymap("n", "<leader>ee", ":lua MiniFiles.open()<CR>", { noremap = true, silent = true })
		vim.api.nvim_set_keymap(
			"n",
			"<leader>ef",
			":lua MiniFiles.open(vim.api.nvim_buf_get_name(0))<CR>",
			{ noremap = true, silent = true }
		)
		vim.api.nvim_set_keymap(
			"n",
			"<leader>do",
			":lua MiniDiff.toggle_overlay()<CR>",
			{ noremap = true, silent = true }
		)
	end,
}
