-- Native Neovim 0.12 Treesitter Configuration
-- Uses Neovim core treesitter APIs - no nvim-treesitter plugin required

-- Add npm global bin to PATH for tree-sitter CLI
vim.env.PATH = vim.env.PATH .. ":/home/ssk/.npm-global/bin"

-- Languages to ensure are installed
local ensure_installed = {
	-- Systems programming
	"c",
	"cpp",
	"rust",
	"go",

	-- Scripting
	"lua",
	"python",
	"bash",
	"javascript",
	"typescript",

	-- Web development
	"html",
	"css",
	"vue",
	"svelte",
	"markdown",
	"markdown_inline",
	"json",
	"yaml",
	"toml",

	-- Data
	"sql",
	"xml",
	"csv",

	-- Build systems
	"dockerfile",
	"make",
	"cmake",

	-- Others
	"vim",
	"query",
	"regex",
}

-- List of supported filetypes for treesitter
local supported_filetypes = {
	lua = true,
	python = true,
	javascript = true,
	typescript = true,
	javascriptreact = true,
	typescriptreact = true,
	go = true,
	rust = true,
	c = true,
	cpp = true,
	css = true,
	html = true,
	json = true,
	yaml = true,
	markdown = true,
	toml = true,
	vim = true,
	bash = true,
	sh = true,
}

-- Function to enable treesitter highlighting for a buffer
local function enable_treesitter(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	local filetype = vim.bo[bufnr].filetype

	if supported_filetypes[filetype] then
		-- Use native vim.treesitter.start() to enable treesitter highlighting
		vim.treesitter.start(bufnr)
	end
end

-- Function to get installed parsers count
local function get_parser_count()
	local count = 0
	for parser, _ in pairs(vim.treesitter.highlighter.get()) do
		count = count + 1
	end
	return count
end

-- Install parsers for a specific language
local function install_parser(lang)
	local ts = require("nvim-treesitter")
	ts.install(lang)
end

-- Setup function - call this to initialize treesitter
local function setup()
	-- Set PATH to include tree-sitter CLI
	vim.env.PATH = "/home/ssk/.npm-global/bin:" .. vim.env.PATH

	-- Try to ensure parsers are installed
	local ts_ok, ts = pcall(require, "nvim-treesitter")
	if ts_ok and ts.install then
		for _, lang in ipairs(ensure_installed) do
			pcall(ts.install, lang)
		end
	end
	-- Silent - no print notifications
end

-- Auto-install parsers when supported file is opened
local function auto_install_parser(args)
	local filetype = vim.bo[args.buf].filetype
	if supported_filetypes[filetype] then
		local ts_ok, ts = pcall(require, "nvim-treesitter")
		if ts_ok and ts.install then
			pcall(ts.install, filetype)
		end
	end
end

-- Setup autocmds
vim.api.nvim_create_autocmd("BufEnter", {
	callback = function(args)
		enable_treesitter(args.buf)
		auto_install_parser(args)
	end,
})

vim.api.nvim_create_autocmd("BufReadPost", {
	callback = function(args)
		enable_treesitter(args.buf)
	end,
})

-- Run setup
setup()

-- Export module
local M = {
	enable = enable_treesitter,
	install = install_parser,
	supported = supported_filetypes,
	get_parser_count = get_parser_count,
}

return M