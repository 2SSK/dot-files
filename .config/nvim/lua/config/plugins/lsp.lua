return {
	{
		"folke/lazydev.nvim",
		ft = "lua",
		opts = { library = { { path = "${3rd}/luv/library", words = { "vim%.uv" } } } },
	},
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = { "saghen/blink.cmp" },
		config = function()
			vim.diagnostic.config({
				signs = {
					text = {
						[vim.diagnostic.severity.ERROR] = " ",
						[vim.diagnostic.severity.WARN] = " ",
						[vim.diagnostic.severity.HINT] = "󰠠 ",
						[vim.diagnostic.severity.INFO] = " ",
					},
				},
				underline = true,
				update_in_insert = false,
				virtual_text = true,
			})

			-- Built in since nvim 0.11: K hover, [d / ]d diagnostics, grn rename, gra action, grr references
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("UserLspConfig", {}),
				callback = function(event)
					local function map(mode, lhs, rhs, desc)
						vim.keymap.set(mode, lhs, rhs, { buffer = event.buf, silent = true, desc = desc })
					end
					map("n", "gd", function() Snacks.picker.lsp_definitions() end, "Definition")
					map("n", "gD", vim.lsp.buf.declaration, "Declaration")
					map("n", "gR", function() Snacks.picker.lsp_references() end, "References")
					map("n", "gi", function() Snacks.picker.lsp_implementations() end, "Implementation")
					map("n", "gt", function() Snacks.picker.lsp_type_definitions() end, "Type definition")
					map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "Code action")
					map("n", "<leader>cr", vim.lsp.buf.rename, "Rename")
					map("n", "<leader>cd", vim.diagnostic.open_float, "Line diagnostics")
					map("n", "<leader>cR", "<cmd>LspRestart<CR>", "Restart LSP")

					local client = vim.lsp.get_client_by_id(event.data.client_id)
					if client and client:supports_method("textDocument/foldingRange") then
						vim.wo.foldmethod = "expr"
						vim.wo.foldexpr = "v:lua.vim.lsp.foldexpr()"
					end
				end,
			})

			-- Copilot as ghost text: Tab accepts (completion.lua), Ctrl+] dismisses.
			-- Sign in once with :LspCopilotSignIn.
			vim.lsp.inline_completion.enable()
			vim.keymap.set("i", "<C-]>", function()
				vim.lsp.inline_completion.enable(false, { bufnr = 0 })
				vim.lsp.inline_completion.enable(true, { bufnr = 0 })
			end, { desc = "Dismiss Copilot suggestion" })

			local servers = {
				copilot = {},
				lua_ls = {
					cmd = { vim.fn.stdpath("data") .. "/mason/bin/lua-language-server" },
					root_markers = { ".git", "init.lua", "lua/" },
					settings = {
						Lua = {
							runtime = { version = "LuaJIT" },
							diagnostics = { globals = { "vim" } },
							workspace = { checkThirdParty = false },
							hints = { enable = false },
							completion = { callSnippet = "Replace" },
							telemetry = { enable = false },
							misc = { param = 25 },
						},
					},
				},
				clangd = {
					init_options = { clangdFileStatus = true },
					filetypes = { "c", "cpp", "objc", "objcpp" },
				},
				pyright = { filetypes = { "python" } },
				ts_ls = { filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" } },
				tailwindcss = {},
				svelte = {},
				emmet_ls = {
					filetypes = { "html", "css", "javascript", "javascriptreact", "typescript", "typescriptreact", "svelte" },
				},
				graphql = { filetypes = { "graphql", "gql", "svelte", "typescriptreact", "javascriptreact" } },
				gopls = {
					cmd = { "gopls", "serve" },
					filetypes = { "go", "gomod", "gowork", "gotmpl" },
					root_markers = { "go.mod", "go.work", ".git" },
				},
				zls = { cmd = { "zls" }, filetypes = { "zig" } },
				rust_analyzer = {
					filetypes = { "rust" },
					root_markers = { "Cargo.toml" },
					settings = { ["rust-analyzer"] = { cargo = { allFeatures = true } } },
				},
			}

			local capabilities = require("blink.cmp").get_lsp_capabilities()
			for server, config in pairs(servers) do
				vim.lsp.config(server, vim.tbl_extend("force", { capabilities = capabilities }, config))
				vim.lsp.enable(server)
			end
		end,
	},
}
