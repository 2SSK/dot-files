return {
	"nvim-treesitter/nvim-treesitter",
	build= ":TSUpdate",
	config = function()
		require("nvim-treesitter.configs").setup({
			ensure_installed = {
				-- Common programming languages
				"c",
				"cpp",
				"python",
				"java",
				"javascript",
				"typescript",
				"go",
				"rust",
				"lua",
				"bash",
				"html",
				"css",
				"json",
				"yaml",

				-- Web development
				"vue",
				"svelte",
				"markdown",
				"markdown_inline",
				"graphql",
				"tsx",

				-- Data formats
				"toml",
				"ini",
				"csv",
				"xml",
				"sql",

				-- System configuration
				"dockerfile",
				"make",
				"cmake",

				-- Scripting
				"perl",
				"ruby",
				"php",
				"elixir",
				"fish",

				-- Others
				"vim",
				"regex",
				"query",
				"haskell",
				"scala",
			},
			auto_install = false,
			highlight = {
				enable = true,
				disable = function(lang, buf)
					local max_filesize = 100 * 1024 -- 100 KB
					local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
					if ok and stats and stats.size > max_filesize then
						return true
					end
				end,
				additional_vim_regex_highlighting = false,
			},
		})
	end,
}
