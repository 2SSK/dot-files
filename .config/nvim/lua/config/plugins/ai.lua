return {
	-- Copilot
	{ "github/copilot.vim" },

	-- Copilot Chat
	{
		{
			"CopilotC-Nvim/CopilotChat.nvim",
			dependencies = {
				{ "github/copilot.vim" }, -- or zbirenbaum/copilot.lua
				{ "nvim-lua/plenary.nvim", branch = "master" }, -- for curl, log and async functions
			},
			build = "make tiktoken", -- Only on MacOS or Linux
			opts = {
				-- See Configuration section for options
			},
			-- See Commands section for default commands if you want to lazy load on them
		},
	},
	-- {
	-- 	"folke/sidekick.nvim",
	-- 	opts = {
	-- 		debug = false,
	-- 		cli = {
	-- 			mux = {
	-- 				-- backend = "zellij",
	-- 				enabled = true,
	-- 				create = "terminal",
	-- 			},
	-- 			tools = {
	-- 				debug = {
	-- 					-- print env and read -p "any key to continue"
	-- 					cmd = { "bash", "-c", "env | sort | bat -l env" },
	-- 				},
	-- 			},
	-- 		},
	-- 	},
	-- 	keys = {
	-- 		{
	-- 			"<leader>aa",
	-- 			function()
	-- 				require("sidekick.cli").toggle()
	-- 			end,
	-- 		},
	-- 		{
	-- 			"<c-.>",
	-- 			function()
	-- 				require("sidekick.cli").toggle()
	-- 			end,
	-- 			desc = "Sidekick Toggle",
	-- 			mode = { "n", "t", "i", "x" },
	-- 		},
	-- 	},
	-- },
}
