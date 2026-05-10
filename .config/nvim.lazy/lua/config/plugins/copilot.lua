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
	-- Copilot Chat
	{
		{
			"CopilotC-Nvim/CopilotChat.nvim",
			dependencies = {
				{ "zbirenbaum/copilot.lua" }, -- or zbirenbaum/copilot.lua
				{ "nvim-lua/plenary.nvim", branch = "master" }, -- for curl, log and async functions
			},
			build = "make tiktoken", -- Only on MacOS or Linux
			opts = {
				-- See Configuration section for options
			},
			-- See Commands section for default commands if you want to lazy load on them
		},
	},
}
