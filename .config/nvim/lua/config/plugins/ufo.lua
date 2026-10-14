-- Folds from the language server, else by indent; everything open to start
return {
	"kevinhwang91/nvim-ufo",
	dependencies = { "kevinhwang91/promise-async" },
	lazy = false,
	init = function()
		vim.o.foldcolumn = "1"
		vim.o.foldlevel = 99
		vim.o.foldlevelstart = 99
		vim.o.foldenable = true
	end,
	config = function()
		local ufo = require("ufo")
		ufo.setup({
			provider_selector = function()
				return { "lsp", "indent" }
			end,
		})
		vim.keymap.set("n", "zR", ufo.openAllFolds, { desc = "Open all folds" })
		vim.keymap.set("n", "zM", ufo.closeAllFolds, { desc = "Close all folds" })
		vim.keymap.set("n", "zK", function()
			if not ufo.peekFoldedLinesUnderCursor() then
				vim.lsp.buf.hover()
			end
		end, { desc = "Peek fold" })
	end,
}
