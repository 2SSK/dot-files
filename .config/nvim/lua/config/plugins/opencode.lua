return {
	"NickvanDyke/opencode.nvim",
	dependencies = {
		{ "folke/snacks.nvim", opts = { input = {}, picker = {}, terminal = {} } },
	},
	config = function()
		---@type opencode.Opts
		vim.g.opencode_opts = {
			auto_reload = true,
			enabled = "snacks",
			-- Don't start a new server; use the existing opencode process
			server = {
				start = function()
					-- Noop - opencode is already running in tmux
				end,
				stop = function()
					-- Noop - don't stop the existing opencode
				end,
				toggle = function()
					-- Noop - don't toggle anything
				end,
			},
			---@type opencode.provider.Snacks
			provider = {
				snacks = {
					win = {
						enter = false, -- Don't auto-focus the pane
						position = "right",
					},
				},
			},
		}

		-- Required for `opts.auto_reload`
		vim.opt.autoread = true
	end,
      -- stylua: ignore
      keys = {
        { "<leader>oa", mode = { "n", "x" }, function() require("opencode").ask("@this: ", { submit = true }) end,      desc = "Ask opencode about this" },
        { "<leader>oa", mode = { "v" },      function() require("opencode").ask("@selection: ", { submit = true }) end, desc = "Ask opencode about selection" },
        { "<leader>op", mode = { "n", "x" }, function() require("opencode").select() end,                               desc = "Select opencode prompt" },
      },
}, {
	"folke/which-key.nvim",
	opts = {
		spec = {
			{ "<leader>a", group = "ai", icon = { icon = " ", color = "green" } },
		},
	},
}
