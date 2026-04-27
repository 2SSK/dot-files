return {
	-- Copilot.lua - modern successor to copilot.vim
	{
		"zbirenbaum/copilot.lua",
		event = "InsertEnter",
		build = ":Copilot auth",
		opts = {
			panel = {
				enabled = true,
				auto_refresh = true,
			},
			suggestion = {
				enabled = true,
				auto_trigger = true,
				debounce = 75,
				keymap = {
					accept = "<C-a>",
					dismiss = "<C-r>",
				},
			},
		},
	},
}
