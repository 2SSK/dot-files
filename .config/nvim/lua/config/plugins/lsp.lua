return {
	{
		"folke/lazydev.nvim", -- Neovim Lua API types for lua_ls (replaces neodev)
		ft = "lua",
		opts = { library = { { path = "${3rd}/luv/library", words = { "vim%.uv" } } } },
	},
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = { "saghen/blink.cmp" },
		config = function()
			-- Enhanced capabilities for autocompletion
			local capabilities = require("blink.cmp").get_lsp_capabilities()

			-- Diagnostic signs configuration using vim.diagnostic.config
			vim.diagnostic.config({
				signs = {
					text = {
						[vim.diagnostic.severity.ERROR] = " ",
						[vim.diagnostic.severity.WARN] = " ",
						[vim.diagnostic.severity.HINT] = "󰠠 ",
						[vim.diagnostic.severity.INFO] = " ",
					},
				},
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
					keymap.set("n", "gR", function() Snacks.picker.lsp_references() end, opts)
					keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
					keymap.set("n", "gd", function() Snacks.picker.lsp_definitions() end, opts)
					keymap.set("n", "gi", function() Snacks.picker.lsp_implementations() end, opts)
					keymap.set("n", "gt", function() Snacks.picker.lsp_type_definitions() end, opts)
					keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)
					keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
					keymap.set("n", "<leader>D", function() Snacks.picker.diagnostics_buffer() end, opts)
					keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts)
					keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
					keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
					keymap.set("n", "K", vim.lsp.buf.hover, opts)
					keymap.set("n", "<leader>rs", ":LspRestart<CR>", opts)

					-- Fold by LSP ranges where the server offers them (else treesitter, see treesitter.lua)
					local client = vim.lsp.get_client_by_id(event.data.client_id)
					if client and client:supports_method("textDocument/foldingRange") then
						vim.wo.foldmethod = "expr"
						vim.wo.foldexpr = "v:lua.vim.lsp.foldexpr()"
					end
				end,
			})

			-- LSP server configurations
			local server_configurations = {
				lua_ls = {
					-- Use mason-installed lua_ls (faster and managed by mason)
					cmd = { vim.fn.stdpath("data") .. "/mason/bin/lua-language-server" },
					root_markers = { ".git", "init.lua", "lua/" },
					settings = {
						Lua = {
							runtime = {
								version = "LuaJIT",
							},
							diagnostics = {
								globals = { "vim" },
							},
							workspace = {
								checkThirdParty = false,
							},
							hints = {
								enable = false,
							},
							completion = {
								callSnippet = "Replace",
							},
							telemetry = {
								enable = false,
							},
							-- Performance optimizations for memory
							misc = {
								-- Limit the number of cached files
								param = 25,
							},
						},
					},
				},
				clangd = {
					capabilities = capabilities,
					init_options = { clangdFileStatus = true },
					filetypes = { "c", "cpp", "objc", "objcpp" },
				},
				pyright = {
					capabilities = capabilities,
					filetypes = { "python" },
				},
				ts_ls = {
					capabilities = capabilities,
					filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
				},
				tailwindcss = {
					capabilities = capabilities,
				},
				svelte = {
					capabilities = capabilities,
				},
				emmet_ls = {
					capabilities = capabilities,
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
				graphql = {
					capabilities = capabilities,
					filetypes = { "graphql", "gql", "svelte", "typescriptreact", "javascriptreact" },
				},
				gopls = {
					capabilities = capabilities,
					cmd = { "gopls", "serve" },
					filetypes = { "go", "gomod", "gowork", "gotmpl" },
					root_markers = { "go.mod", "go.work", ".git" },
				},
				zls = {
					capabilities = capabilities,
					cmd = { "zls" },
					filetypes = { "zig" },
				},
				rust_analyzer = {
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
	},
}
