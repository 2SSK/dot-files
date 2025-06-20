return {
	"folke/tokyonight.nvim",
	name = "tokyonight",
	priority = 1000,
	opts = {
		transparent = false,
	},
	config = function()
		require("tokyonight").setup({
			vim.cmd([[colorscheme tokyonight]]),
		})
	end,
}
