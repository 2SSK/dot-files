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

		-- Mini Pairs
		require("mini.pairs").setup()

		-- Mini Surround
		require("mini.surround").setup()
	end,
}
