return {
	"stevearc/conform.nvim",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local conform = require("conform")
		local opts = { lsp_fallback = true, async = false, timeout_ms = 1000 }

		conform.setup({
			formatters_by_ft = {
				javascript = { "prettier" },
				typescript = { "prettier" },
				javascriptreact = { "prettier" },
				typescriptreact = { "prettier" },
				css = { "prettier" },
				html = { "prettier" },
				json = { "prettier" },
				yaml = { "prettier" },
				markdown = { "prettier" },
				graphql = { "prettier" },
				liquid = { "prettier" },
				lua = { "stylua" },
				python = { "isort", "black" },
				sh = { "shfmt" }, -- tabs, as the repo (beautysh turned them into four spaces)
				bash = { "shfmt" },
			},
			-- shfmt as it is: tabs, or a project's .editorconfig (conform otherwise adds -i <shiftwidth>
			-- when expandtab is on, turning tabs into spaces)
			formatters = {
				shfmt = { args = { "-filename", "$FILENAME" } },
			},
			format_on_save = opts,
		})

		vim.keymap.set({ "n", "v" }, "<leader>cf", function()
			conform.format(opts)
		end, { desc = "Format file or selection" })
	end,
}
