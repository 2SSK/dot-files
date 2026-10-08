-- nvim-treesitter (main branch): installs parsers (needs the tree-sitter CLI) and turns on
-- highlighting, indentation and folding per buffer. Visual-mode an/in (built into nvim 0.12)
-- grow and shrink the selection by syntax node.
local parsers = {
	"bash", "c", "cpp", "css", "diff", "dockerfile", "go", "graphql", "html", "java", "javascript",
	"json", "lua", "luadoc", "make", "markdown", "markdown_inline", "python", "query", "regex",
	"rust", "sql", "svelte", "toml", "tsx", "typescript", "vim", "vimdoc", "yaml", "zig",
}

return {
	"nvim-treesitter/nvim-treesitter",
	branch = "main",
	lazy = false,
	build = ":TSUpdate",
	dependencies = { { "nvim-treesitter/nvim-treesitter-textobjects", branch = "main" } }, -- queries for mini.ai
	config = function()
		require("nvim-treesitter").install(parsers) -- missing ones only, in the background
		vim.api.nvim_create_autocmd("FileType", {
			group = vim.api.nvim_create_augroup("treesitter-start", { clear = true }),
			callback = function(event)
				if not pcall(vim.treesitter.start, event.buf) then
					return -- no parser for this filetype
				end
				vim.bo[event.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
				vim.wo.foldmethod = "expr"
				vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
			end,
		})
	end,
}
