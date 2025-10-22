return {
	"kristijanhusak/vim-dadbod-ui",
	dependencies = {
		{ "tpope/vim-dadbod", lazy = true },
		{ "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "plsql" }, lazy = true }, -- Optional
	},
	cmd = {
		"DBUI",
		"DBUIToggle",
		"DBUIAddConnection",
		"DBUIFindBuffer",
	},
	init = function()
		-- Your DBUI configuration
		vim.g.db_ui_use_nerd_fonts = 1

		-- Keybindings
		vim.keymap.set('n', '<leader>db', '<cmd>DBUIToggle<CR>', { desc = 'Toggle DB UI' })
		vim.keymap.set('n', '<leader>da', '<cmd>DBUIAddConnection<CR>', { desc = 'Add DB Connection' })
		vim.keymap.set('n', '<leader>df', '<cmd>DBUIFindBuffer<CR>', { desc = 'Find DB Buffer' })
	end,
}
