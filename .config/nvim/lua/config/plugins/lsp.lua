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
						[vim.diagnostic.severity.ERROR] = "\u{f057} ",
						[vim.diagnostic.severity.WARN] = "\u{f071} ",
						[vim.diagnostic.severity.HINT] = "\u{f0820} ",
						[vim.diagnostic.severity.INFO] = "\u{f05a} ",
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
					map("n", "<leader>xd", vim.diagnostic.open_float, "Line diagnostics")
					map("n", "<leader>cR", "<cmd>LspRestart<CR>", "Restart LSP")
				end,
			})

			local servers = {
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
				emmet_ls = {
					filetypes = { "html", "css", "javascript", "javascriptreact", "typescript", "typescriptreact" },
				},
				graphql = { filetypes = { "graphql", "gql", "typescriptreact", "javascriptreact" } },
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

			-- Mason installs the others; these come with their toolchain (dev package layer) and start
			-- only where it's installed
			local from_system = { gopls = true, rust_analyzer = true }
			local capabilities = require("blink.cmp").get_lsp_capabilities()
			for server, config in pairs(servers) do
				vim.lsp.config(server, vim.tbl_deep_extend("force", { capabilities = capabilities }, config))
				if not from_system[server] or vim.fn.executable(vim.lsp.config[server].cmd[1]) == 1 then
					vim.lsp.enable(server)
				end
			end
		end,
	},
}
