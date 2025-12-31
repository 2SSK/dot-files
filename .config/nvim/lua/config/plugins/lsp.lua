return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"hrsh7th/cmp-nvim-lsp",
		{ "antosha417/nvim-lsp-file-operations", config = true },
		{ "folke/neodev.nvim", opts = {} },
	},
	config = function()
		-- Import required plugins
		local cmp_nvim_lsp = require("cmp_nvim_lsp")
		local on_attach = require("neodev").on_attach

		-- Enhanced capabilities for autocompletion
		local capabilities = cmp_nvim_lsp.default_capabilities()

		-- Diagnostic signs configuration
		local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
		for type, icon in pairs(signs) do
			local hl = "DiagnosticSign" .. type
			vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
		end
		vim.diagnostic.config({
			signs = true,
			underline = true,
			update_in_insert = false,
			virtual_text = true,
		})

		-- Format on save
		vim.api.nvim_create_autocmd("BufWritePre", {
			callback = function(event)
				local excluded_filetypes = { "markdown", "json", "yaml" }
				local filetype = vim.bo[event.buf].filetype
				local client = vim.lsp.get_clients({ bufnr = event.buf })[1]
				if
					client
					and client:supports_method("textDocument/formatting")
					and not vim.tbl_contains(excluded_filetypes, filetype)
				then
					vim.lsp.buf.format({ bufnr = event.buf, async = false })
				end
			end,
		})

		-- LSP key mappings
		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("UserLspConfig", {}),
			callback = function(event)
				local opts = { buffer = event.buf, silent = true }
				local keymap = vim.keymap

				-- Keybindings for LSP
				keymap.set("n", "gR", "<cmd>Telescope lsp_references<CR>", opts)
				keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
				keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts)
				keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts)
				keymap.set("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", opts)
				keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)
				keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
				keymap.set("n", "<leader>D", "<cmd>Telescope diagnostics bufnr=0<CR>", opts)
				keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts)
				keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
				keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
				keymap.set("n", "K", vim.lsp.buf.hover, opts)
				keymap.set("n", "<leader>rs", ":LspRestart<CR>", opts)
			end,
		})

		-- LSP server configurations
		local server_configurations = {
			lua_ls = {
				settings = {
					Lua = {
						diagnostics = { globals = { "vim" } },
						completion = { callSnippet = "Replace" },
					},
				},
			},
			emmet_ls = {
				filetypes = {
					"html",
					"css",
					"javascript",
					"javascriptreact",
					"typescript",
					"typescriptreact",
					"svelte",
				},
			},
			clangd = {
				init_options = { clangdFileStatus = true },
				filetypes = { "c", "cpp", "objc", "objcpp" },
			},
			pyright = {
				on_attach = on_attach,
				capabilities = capabilities,
				filetypes = { "python" },
			},
			-- pylint = {
			-- 	on_attach = on_attach,
			-- 	capabilities = capabilities,
			-- 	filetypes = { "python" },
			-- },
			ts_ls = {
				filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
			},
			tailwindcss = {
				on_attach = on_attach,
				capabilities = capabilities,
			},
			svelte = {
				on_attach = function(client, bufnr)
					vim.api.nvim_create_autocmd("BufWritePost", {
						pattern = { "*.js", "*.ts" },
						callback = function(ctx)
							client.notify("$/onDidChangeTsOrJsFile", { uri = ctx.match })
						end,
					})
				end,
			},
			graphql = {
				filetypes = { "graphql", "gql", "svelte", "typescriptreact", "javascriptreact" },
			},
			gopls = {
				on_attach = on_attach,
				capabilities = capabilities,
				cmd = { "gopls", "serve" },
				filetypes = { "go", "gomod", "gowork", "gotmpl" },
				root_markers = { "go.mod", "go.work", ".git" },
			},
			zls = {
				on_attach = on_attach,
				capabilities = capabilities,
				cmd = { "zls" },
				filetypes = { "zig" },
			},
			rust_analyzer = {
				on_attach = on_attach,
				capabilities = capabilities,
				filetypes = { "rust" },
				root_markers = { "Cargo.toml" },
				settings = {
					["rust-analyzer"] = {
						cargo = {
							allFeatures = true,
						},
					},
				},
			},
		}

		-- Apply server configurations
		for server, config in pairs(server_configurations) do
			vim.lsp.config(server, vim.tbl_extend("force", { capabilities = capabilities }, config))
		end

		-- Enable the configured servers
		for server, _ in pairs(server_configurations) do
			vim.lsp.enable(server)
		end
	end,
}
