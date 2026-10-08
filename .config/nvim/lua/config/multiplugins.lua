local silicon_theme = (vim.env.XDG_STATE_HOME or (vim.env.HOME .. "/.local/state")) .. "/desktop/theme/silicon.tmTheme"

local function silicon_background()
	local theme = require("config.theme").read()
	return theme and theme.palette.base00 or nil
end

return {
	{ "christoomey/vim-tmux-navigator" },
	{
		"akinsho/bufferline.nvim",
		version = "*",
		event = "VeryLazy",
		opts = {
			options = {
				diagnostics = "nvim_lsp",
				mode = "tabs",
				show_buffer_close_icons = false,
			},
		},
	},
	{
		"akinsho/git-conflict.nvim",
		version = "*",
		event = { "BufReadPre", "BufNewFile" },
		opts = {}, -- in a conflicted file: co ours, ct theirs, cb both, c0 none, ]x / [x next / previous
		keys = { { "<leader>gx", "<cmd>GitConflictListQf<CR>", desc = "List conflicts" } },
	},
	{
		"michaelrommel/nvim-silicon",
		main = "nvim-silicon",
		cmd = "Silicon",
		opts = {
			font = "JetBrains Mono Nerd Font=34;Noto Color Emoji=34",
			theme = silicon_theme,
			background = silicon_background(),
			window_title = function()
				return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":t")
			end,
		},
		keys = {
			{
				"<leader>ss",
				function()
					local silicon = require("nvim-silicon")
					-- the background as of now, in case the theme changed since nvim started
					silicon.shoot(vim.tbl_extend("force", silicon.options, { background = silicon_background() }))
				end,
				mode = "x",
				desc = "Screenshot selection",
			},
		},
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
