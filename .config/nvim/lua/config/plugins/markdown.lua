return {
	{
		"iamcco/markdown-preview.nvim",
		cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
		ft = { "markdown" },
		-- the plugin's prebuilt preview server; mkdp#util#install() isn't loaded yet when lazy builds
		build = "cd app && ./install.sh",
		init = function()
			vim.g.mkdp_filetypes = { "markdown" }
		end,
		keys = { { "<leader>md", "<cmd>MarkdownPreviewToggle<CR>", desc = "Markdown preview" } },
	},
	{
		"MeanderingProgrammer/render-markdown.nvim",
		ft = { "markdown" },
		opts = {},
		dependencies = { "nvim-treesitter/nvim-treesitter", "echasnovski/mini.nvim" },
	},
}
