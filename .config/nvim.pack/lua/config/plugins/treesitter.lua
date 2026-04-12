-- Native Neovim Treesitter Configuration
-- Uses Neovim core treesitter APIs

-- List of supported filetypes for treesitter
local supported_filetypes = {
	lua = true,
	python = true,
	javascript = true,
	typescript = true,
	javascriptreact = true,
	typescriptreact = true,
	tsx = true,
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
		local lang = filetype
		if filetype == "typescriptreact" then
			lang = "tsx"
		elseif filetype == "javascriptreact" then
			lang = "jsx"
		end
		vim.treesitter.start(bufnr, lang)
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

-- Setup autocmds
vim.api.nvim_create_autocmd("BufEnter", {
	callback = function(args)
		enable_treesitter(args.buf)
	end,
})

vim.api.nvim_create_autocmd("BufReadPost", {
	callback = function(args)
		enable_treesitter(args.buf)
	end,
})

-- Export module
local M = {
	enable = enable_treesitter,
	supported = supported_filetypes,
	get_parser_count = get_parser_count,
}

return M