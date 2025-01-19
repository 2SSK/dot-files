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

		-- Mini Files
		require("mini.files").setup({
			vim.api.nvim_set_keymap("n", "<leader>e", ":lua MiniFiles.open()<CR>", { noremap = true, silent = true }),
		})
	end,
}
