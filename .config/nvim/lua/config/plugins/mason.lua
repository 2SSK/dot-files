return {
	"williamboman/mason.nvim",
	dependencies = {
		"williamboman/mason-lspconfig.nvim",
		"WhoIsSethDaniel/mason-tool-installer.nvim",
	},
	config = function()
		require("mason").setup({
			ui = {
				icons = { package_installed = "✓", package_pending = "➜", package_uninstalled = "✗" },
				border = "rounded",
			},
		})
		---@diagnostic disable-next-line: missing-fields
		require("mason-lspconfig").setup({
			ensure_installed = {
				"copilot",
				"pyright",
				"html",
				"zls",
				"cssls",
				"tailwindcss",
				"svelte",
				"lua_ls",
				"graphql",
				"emmet_ls",
				"prismals",
				"clangd",
				"gopls",
			},
		})
		require("mason-tool-installer").setup({
			ensure_installed = { "prettier", "stylua", "delve" },
		})
	end,
}
