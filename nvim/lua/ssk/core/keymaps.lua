vim.g.mapleader = " "

local keymap = vim.keymap

keymap.set("i", "jk", "<ESC>", { desc = "Exit insert mode with jk" })

keymap.set("n", "<leader>nh", ":nohl<CR>", { desc = "Clear search highlights" })

-- increment/decrement numbers
keymap.set("n", "<leader>+", "<C-a>", { desc = "Increment number" }) -- increment
keymap.set("n", "<leader>-", "<C-x>", { desc = "Decrement number" }) -- decrement

-- window management
keymap.set("n", "<leader>sv", "<C-w>v", { desc = "Split window vertically" }) -- split window vertically
keymap.set("n", "<leader>sh", "<C-w>s", { desc = "Split window horizontally" }) -- split window horizontally
keymap.set("n", "<leader>se", "<C-w>=", { desc = "Make splits equal size" }) -- make split windows equal width & height
keymap.set("n", "<leader>sx", "<cmd>close<CR>", { desc = "Close current split" }) -- close current split window

keymap.set("n", "<leader>to", "<cmd>tabnew<CR>", { desc = "Open new tab" }) -- open new tab
keymap.set("n", "<leader>tx", "<cmd>tabclose<CR>", { desc = "Close current tab" }) -- close current tab
keymap.set("n", "<leader>tn", "<cmd>tabn<CR>", { desc = "Go to next tab" }) --  go to next tab
keymap.set("n", "<leader>tp", "<cmd>tabp<CR>", { desc = "Go to previous tab" }) --  go to previous tab
keymap.set("n", "<leader>tf", "<cmd>tabnew %<CR>", { desc = "Open current buffer in new tab" }) --  move current buffer to new tab

-- Execute programs from nvim
vim.api.nvim_set_keymap("n", "<C-r>", "", {
  noremap = true,
  silent = true,
  callback = function()
    local file_path = vim.api.nvim_buf_get_name(0)
    local file_name = vim.fn.fnamemodify(file_path, ":t")
    local file_type = vim.bo.filetype

    if file_type == "lua" then
      vim.cmd(":terminal lua " .. file_path)
    elseif file_type == "c" then
      vim.cmd(
        ":terminal gcc " .. file_path .. " -o " .. file_name:gsub("%.c$", "") .. " && ./" .. file_name:gsub("%.c$", "")
      )
    elseif file_type == "cpp" then
      vim.cmd(
        ":terminal g++ "
          .. file_path
          .. " -o "
          .. file_name:gsub("%.cpp$", "")
          .. " && ./"
          .. file_name:gsub("%.cpp$", "")
      )
    elseif file_type == "python" then
      vim.cmd(":terminal python3 " .. file_path)
    elseif file_type == "go" then
      vim.cmd(":terminal go run " .. file_path)
    elseif file_type == "rust" then
      vim.cmd(
        ":terminal rustc "
          .. file_path
          .. " -o "
          .. file_name:gsub("%.rs$", "")
          .. " && ./"
          .. file_name:gsub("%.rs$", "")
      )
    elseif file_type == "java" then
      vim.cmd(":terminal javac " .. file_path .. " && java " .. file_name:gsub("%.java$", ""))
    elseif file_type == "javascript" then
      vim.cmd(":terminal node " .. file_path)
    elseif file_type == "typescript" then
      vim.cmd(":terminal ts-node " .. file_path)
    elseif file_type == "sh" then
      vim.cmd(":terminal bash " .. file_path)
    else
      print("File type not supported for this command")
    end
  end,
})
