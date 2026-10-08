vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

local map = vim.keymap.set

map("i", "jk", "<Esc>")
map("n", "<Esc>", "<cmd>nohlsearch<CR><Esc>")
map("n", "<leader>w", "<cmd>w<CR>", { desc = "Save" })
map("n", "<leader>q", "<cmd>q<CR>", { desc = "Quit" })
map("n", "<leader>Q", "<cmd>qa<CR>", { desc = "Quit all" })

map("n", "<leader>sv", "<C-w>v", { desc = "Split vertically" })
map("n", "<leader>sh", "<C-w>s", { desc = "Split horizontally" })
map("n", "<leader>se", "<C-w>=", { desc = "Equalise splits" })
map("n", "<leader>sx", "<cmd>close<CR>", { desc = "Close split" })
map("n", "<C-Up>", "<cmd>resize -3<CR>")
map("n", "<C-Down>", "<cmd>resize +3<CR>")
map("n", "<C-Left>", "<cmd>vertical resize -3<CR>")
map("n", "<C-Right>", "<cmd>vertical resize +3<CR>")

map("n", "<leader>to", "<cmd>tabnew<CR>", { desc = "New tab" })
map("n", "<leader>tx", "<cmd>tabclose<CR>", { desc = "Close tab" })
map("n", "<leader>tf", "<cmd>tabnew %<CR>", { desc = "Open buffer in new tab" })
map("n", "<S-l>", "<cmd>tabnext<CR>", { desc = "Next tab" })
map("n", "<S-h>", "<cmd>tabprevious<CR>", { desc = "Previous tab" })

map("n", "<leader>cx", "<cmd>!./run.sh %<CR>", { desc = "Run ./run.sh on this file" })
