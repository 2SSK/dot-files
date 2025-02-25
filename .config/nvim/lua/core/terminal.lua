local keymap = vim.keymap

-- Global variable to store Terminal job_id
local job_id = 0

-- Toggle Terminal Mode
keymap.set("n", "<C-t>", ":vsp | terminal<CR>i", { desc = "Open terminal in vertical split" })
keymap.set("t", "jk", [[<C-\><C-n>]], { desc = "Open terminal in vertical split" })

-- Open terminal in a new vertical split
keymap.set("n", "<space>st", function()
	vim.cmd.vnew()
	vim.cmd.term()
	vim.cmd.wincmd("J")
	vim.api.nvim_win_set_height(0, 10)

	job_id = vim.bo.channel
end)

-- Command to compile and run C++ code
keymap.set("n", "<space>runcpp", function()
	local command = "gc output *.cpp && ./output\r\n"
	vim.fn.chansend(job_id, { command })
end)

keymap.set("n", "<space>run", function()
	local command = "bash *.sh\r\n"
	vim.fn.chansend(job_id, { command })
end)
