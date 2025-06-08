vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

local keymap = vim.keymap

keymap.set("i", "jk", "<ESC>", { desc = "Exit insert mode with jk" })
keymap.set("n", "<leader>w", ":w<CR>", { desc = "Save file" })
keymap.set("n", "<leader>q", ":q<CR>", { desc = "Close file" })
keymap.set("n", "<leader>wq", ":wqa!<CR>", { desc = "Save and close all files" })
keymap.set("n", "<leader>qa", ":qa<CR>", { desc = "Close all files" })
keymap.set("n", "<leader>wx", ":w<bar>tabclose<CR>", { desc = "Save file and close tab" })
keymap.set("n", "<leader>nh", ":nohl<CR>", { desc = "Clear search highlights" })

keymap.set("n", "<leader>sv", "<C-w>v", { desc = "Split window vertically" })
keymap.set("n", "<leader>sh", "<C-w>s", { desc = "Split window horizontally" })
keymap.set("n", "<leader>se", "<C-w>=", { desc = "Make splits equal size" })
keymap.set("n", "<leader>sx", "<cmd>close<CR>", { desc = "Close current split" })

-- Tab navigation commands
keymap.set("n", "<leader>to", "<cmd>tabnew<CR>", { desc = "Open new tab" })
keymap.set("n", "<leader>tx", "<cmd>tabclose<CR>", { desc = "Close current tab" })
keymap.set("n", "<leader>tn", "<cmd>tabn<CR>", { desc = "Go to next tab" })
keymap.set("n", "<leader>tp", "<cmd>tabp<CR>", { desc = "Go to previous tab" })
keymap.set("n", "<leader>tf", "<cmd>tabnew %<CR>", { desc = "Open current buffer in new tab" })

-- Dismiss Noice Message
keymap.set("n", "<leader>nd", "<cmd>NoiceDismiss<CR>", { desc = "Dismiss Noice Message" })

-- Zen mode toggle
keymap.set("n", "<leader>zm", ":ZenMode<CR>", { desc = "Toggle Zen Mode" })

-- Silicon command
keymap.set("v", "<leader>ss", ":Silicon<CR>", { desc = "Screenshot Code" })

-- Resize window
keymap.set("n", "<C-Up>", ":resize -3<CR>")
keymap.set("n", "<C-Down>", ":resize +3<CR>")
keymap.set("n", "<C-Left>", ":vertical resize -3<CR>")
keymap.set("n", "<C-Right>", ":vertical resize +3<CR>")

-- Disable default Tab mapping to avoid conflicts
vim.g.copilot_no_tab_map = true

-- Custom keybindings for Copilot
vim.api.nvim_set_keymap("i", "<C-a>", "copilot#Accept('<CR>')", { expr = true, silent = true, script = true })
vim.api.nvim_set_keymap("i", "<C-r>", "<Plug>(copilot-dismiss)", { silent = true })
vim.api.nvim_set_keymap("n", "<leader>ct", ":Copilot toggle<CR>", { silent = true, noremap = true })
