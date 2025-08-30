return {
	"catppuccin/nvim",
	name = "catppuccin",
	priority = 1000,
	config = function()
		local transparent = true
		require("catppuccin").setup({
			flavour = "mocha", -- latte, frappe, macchiato, mocha

			transparent_background = transparent,
			float = {
				transparent = transparent,
			},
		})
		vim.cmd.colorscheme("catppuccin")
	end,
}
