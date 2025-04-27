require("core")
require("config.lazy")

vim.opt.shada = ""

vim.keymap.set("n", "<space><space>x", "<cmd>source %<CR>")

vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking (copying) text",
	group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
	callback = function()
		vim.hl.on_yank()
	end,
})
