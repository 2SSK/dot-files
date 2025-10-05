vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

local keymap = vim.keymap

keymap.set("i", "jk", "<ESC>")
keymap.set("n", "<leader>nh", ":nohl<CR>")

keymap.set("n", "<leader>w", ":w<CR>")
keymap.set("n", "<leader>wq", ":wq<CR>")
keymap.set("n", "<leader>q", ":q<CR>")
keymap.set("n", "<leader>qa", ":qa<CR>")

-- Window Split Command
keymap.set("n", "<leader>sv", "<C-w>v")
keymap.set("n", "<leader>sh", "<C-w>s")
keymap.set("n", "<leader>se", "<C-w>=")
keymap.set("n", "<leader>sx", "<cmd>close<CR>")

-- Tab Navigation
keymap.set("n", "<leader>to", "<cmd>tabnew<CR>")
keymap.set("n", "<leader>tx", "<cmd>tabclose<CR>")
keymap.set("n", "<S-l>", "<cmd>tabn<CR>")
keymap.set("n", "<S-h>", "<cmd>tabp<CR>")
keymap.set("n", "<leader>tf", "<cmd>tabnew %<CR>")

-- Zen mode toggle
keymap.set("n", "<leader>zm", ":ZenMode<CR>")

-- Silicon command
keymap.set("v", "<leader>ss", ":Silicon<CR>")

-- Resize window commands
keymap.set("n", "<C-Up>", ":resize -3<CR>")
keymap.set("n", "<C-Down>", ":resize +3<CR>")
keymap.set("n", "<C-Left>", ":vertical resize -3<CR>")
keymap.set("n", "<C-Right>", ":vertical resize +3<CR>")

-- Copilot suggestions commands
vim.api.nvim_set_keymap("i", "<C-a>", "copilot#Accept('<CR>')", { expr = true, silent = true, script = true })
vim.api.nvim_set_keymap("i", "<C-r>", "<Plug>(copilot-dismiss)", { silent = true })
keymap.set("n", "<leader>aa", "<cmd>CopilotChatToggle<cr>", { desc = "Toggle Copilot Chat" })
keymap.set("n", "<leader>chl", "<cmd>CopilotChatReset<cr>")
