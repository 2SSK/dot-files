local keymap = vim.keymap

local job_id = 0

-- Toggle Terminal Mode
keymap.set("n", "<C-t>", ":vsp | terminal<CR>i")
keymap.set("t", "jk",[[<C-\><C-n>]])

-- Open terminal in a new vertical split
keymap.set("n","<space>st", function()
  vim.cmd.vnew()
  vim.cmd.term()
  vim.cmd.wincmd("J")
  vim.api.nvim_win_set_height(0,10)

  job_id = vim.bo.channel
end)
