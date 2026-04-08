require("snacks").setup({
  picker = {
    reverse = false,
    sources = {
      files = {
        layout = { preview = false },
        hidden = true,
      },
      explorer = {
        hidden = true,
        layout = { preset = "sidebar", layout = { position = "right", width = 50 } },
        git_status = true,
      },
    },
  },
})

vim.keymap.set("n", "<leader>ee", function()
  Snacks.explorer()
end, { desc = "File Explorer" })

vim.keymap.set("n", "<leader>ef", function()
  Snacks.picker.explorer({ cwd = vim.fn.getcwd() })
end, { desc = "Explorer (cwd)" })

vim.keymap.set("n", "<leader>gi", function()
  Snacks.picker.gh_issue()
end, { desc = "GitHub Issues (open)" })

vim.keymap.set("n", "<leader>gI", function()
  Snacks.picker.gh_issue({ state = "all" })
end, { desc = "GitHub Issues (all)" })

vim.keymap.set("n", "<leader>gp", function()
  Snacks.picker.gh_pr()
end, { desc = "GitHub Pull Requests (open)" })

vim.keymap.set("n", "<leader>gP", function()
  Snacks.picker.gh_pr({ state = "all" })
end, { desc = "GitHub Pull Requests (all)" })
