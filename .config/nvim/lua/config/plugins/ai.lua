return {
	-- Copilot
	{ "github/copilot.vim" },

	-- Copilot Chat
	-- {
	-- 	{
	-- 		"CopilotC-Nvim/CopilotChat.nvim",
	-- 		dependencies = {
	-- 			{ "github/copilot.vim" }, -- or zbirenbaum/copilot.lua
	-- 			{ "nvim-lua/plenary.nvim", branch = "master" }, -- for curl, log and async functions
	-- 		},
	-- 		build = "make tiktoken", -- Only on MacOS or Linux
	-- 		opts = {
	-- 			-- See Configuration section for options
	-- 		},
	-- 		-- See Commands section for default commands if you want to lazy load on them
	-- 	},
	-- },

	-- opencode
	{
		{
			"NickvanDyke/opencode.nvim",
			dependencies = {
				{ "folke/snacks.nvim", opts = { input = {}, picker = {}, terminal = {} } },
			},
			config = function()
				---@type opencode.Opts
				vim.g.opencode_opts = {
					auto_reload = true,
					enabled = "snacks",
					---@type opencode.provider.Snacks
					provider = {
						snacks = {
							win = {
								enter = true,
							},
						},
					},
				}

				-- Required for `opts.auto_reload`
				vim.opt.autoread = true
			end,
    -- stylua: ignore
    keys = {
      { "<M-;>", mode = { "n", "t" }, function() require("opencode").toggle() end, desc = "Toggle embedded opencode" },
      { "<M-i>", mode = {"n", "x"}, function() require("opencode").ask("@this: ", { submit = true }) end, desc = "Ask about this" },
      { "<leader>ap", mode = { "n", "x" }, function() require("opencode").select() end, desc = "Select prompt" },
    },
		},

		{
			"folke/which-key.nvim",
			opts = {
				spec = {
					{ "<leader>a", group = "ai", icon = { icon = " ", color = "green" } },
				},
			},
		},
	},
}
