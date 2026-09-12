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

		-- Mini Diff
		require("mini.diff").setup()

		vim.keymap.set("n", "<leader>do", function()
			MiniDiff.toggle_overlay(0)
		end, { desc = "Toggle diff overlay" })
	end,
}
