local cmp_nvim_lsp = require("cmp_nvim_lsp")

-- Setup neodev for Neovim plugin development
require("neodev").setup({
	override = function(root, options)
		options.library.plugins = true
		options.library.runtime = true
		options.library.vimdoc = true
	end,
})

local capabilities = cmp_nvim_lsp.default_capabilities()

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

vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("UserLspConfig", {}),
	callback = function(event)
		local opts = { buffer = event.buf, silent = true }
		local keymap = vim.keymap

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

-- Basic on_attach function
local function on_attach(client, bufnr)
	-- Set omnifunc for buffer
	if bufnr then
		vim.bo[bufnr].omnifunc = "v:lua.vim.lsp.omnifunc"
	end
end

-- Get nvim config as root directory
local nvim_config_dir = vim.fn.stdpath("config")

local server_configurations = {
	lua_ls = {
		on_attach = function(client, bufnr)
			-- Set workspace folder to config directory
			if client.config.workspaceFolders then
				client.config.workspaceFolders = {
					{ name = "nvim-config", uri = "file://" .. nvim_config_dir }
				}
			end
			on_attach(client, bufnr)
		end,
		root_dir = function(fname)
			-- Use nvim config as root when in ~/.config/nvim
			return nvim_config_dir
		end,
		init_options = {
			-- Set runtime path for lua language server
			runtime = { version = "LuaJIT" },
			-- Don't warn about workspace
			diagnostics = {
				globals = { "vim" },
			},
		},
		settings = {
			Lua = {
				diagnostics = { 
					globals = { "vim" },
					disable = { "lowercase-level" },
				},
				completion = { callSnippet = "Replace" },
				workspace = {
					library = vim.api.nvim_get_runtime_file("", true),
					checkThirdParty = false,
				},
				telemetry = { enable = false },
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

for server, config in pairs(server_configurations) do
	vim.lsp.config(server, vim.tbl_extend("force", { capabilities = capabilities }, config))
end

for server, _ in pairs(server_configurations) do
	vim.lsp.enable(server)
end
-- Silent - no print notifications