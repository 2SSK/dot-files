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

-- Markdown preview toggle
keymap.set("n", "<leader>md", ":MarkdownPreviewToggle<CR>")

-- Resize window commands
keymap.set("n", "<C-Up>", ":resize -3<CR>")
keymap.set("n", "<C-Down>", ":resize +3<CR>")
keymap.set("n", "<C-Left>", ":vertical resize -3<CR>")
keymap.set("n", "<C-Right>", ":vertical resize +3<CR>")

-- Copilot.lua suggestions commands (copilot.vim keymaps updated)
-- Accept suggestion with Ctrl+a
vim.api.nvim_set_keymap("i", "<C-a>", "<cmd>CopilotSuggestionAccept<CR>", { silent = true })
-- Accept suggestion with Tab (alternative)
vim.api.nvim_set_keymap("i", "<Tab>", "copilot#Accept()", { expr = true, silent = true })
-- Dismiss suggestion with Ctrl+r
vim.api.nvim_set_keymap("i", "<C-r>", "<cmd>CopilotSuggestionDismiss<CR>", { silent = true })
-- Toggle copilot
keymap.set("n", "<leader>cd", ":Copilot enable<CR>")
keymap.set("n", "<leader>ce", ":Copilot disable<CR>")

-- DSA commands
keymap.set("n", "<leader>cr", ":!./run.sh %<CR>")
