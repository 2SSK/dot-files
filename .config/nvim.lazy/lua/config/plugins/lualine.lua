return {
	"nvim-lualine/lualine.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	event = "VeryLazy",
	opts = {
		options = {
			icon_enabled = true,
			theme = "auto",
			component_seperators = "|",
			section_separators = { left = "", right = "" },
		},
	},
}
