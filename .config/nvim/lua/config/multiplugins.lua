-- Small plugins that need little or no configuration
return {
	{ "christoomey/vim-tmux-navigator" }, -- Ctrl+h/j/k/l across nvim splits and tmux panes
	{
		"michaelrommel/nvim-silicon",
		cmd = "Silicon",
		config = function()
			require("silicon").setup({
				font = "JetBrains Mono Nerd Font=34;Noto Color Emoji=34",
				theme = "Dracula",
				background = "#94e2d5",
				window_title = function()
					return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf()), ":t")
				end,
			})
		end,
	},
	{
		"rachartier/tiny-cmdline.nvim",
		init = function()
			vim.o.cmdheight = 0
			require("vim._core.ui2").enable({})
		end,
		config = function()
			require("tiny-cmdline").setup()
		end,
	},
}
