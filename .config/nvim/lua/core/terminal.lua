local map = vim.keymap.set

map("n", "<C-t>", "<cmd>vsplit | terminal<CR>i", { desc = "Terminal in a vertical split" })
map("t", "jk", [[<C-\><C-n>]])
map("n", "<leader>st", function()
	vim.cmd.new()
	vim.cmd.terminal()
	vim.cmd.wincmd("J")
	vim.api.nvim_win_set_height(0, 10)
end, { desc = "Terminal below" })
