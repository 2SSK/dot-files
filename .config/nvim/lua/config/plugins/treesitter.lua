-- nvim-treesitter (main branch) installs parsers with the tree-sitter CLI; highlighting and
-- indentation are turned on per buffer (folds: ufo.lua).
local parsers = {
	"bash", "c", "cpp", "css", "diff", "dockerfile", "go", "graphql", "html", "java", "javascript",
	"json", "lua", "luadoc", "make", "markdown", "markdown_inline", "python", "query", "regex",
	"rust", "sql", "toml", "tsx", "typescript", "vim", "vimdoc", "yaml", "zig",
}

return {
	"nvim-treesitter/nvim-treesitter",
	branch = "main",
	lazy = false,
	build = ":TSUpdate",
	dependencies = { { "nvim-treesitter/nvim-treesitter-textobjects", branch = "main" } },
	config = function()
		require("nvim-treesitter").install(parsers)
		vim.api.nvim_create_autocmd("FileType", {
			group = vim.api.nvim_create_augroup("treesitter-start", { clear = true }),
			callback = function(event)
				if not pcall(vim.treesitter.start, event.buf) then
					return
				end
				vim.bo[event.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
			end,
		})
	end,
}
