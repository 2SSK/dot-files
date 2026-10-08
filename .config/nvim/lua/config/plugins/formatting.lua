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
				sh = { "beautysh" },
				bash = { "beautysh" },
			},
			format_on_save = opts,
		})

		vim.keymap.set({ "n", "v" }, "<leader>cf", function()
			conform.format(opts)
		end, { desc = "Format file or selection" })
	end,
}
