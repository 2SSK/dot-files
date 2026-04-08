require("oil").setup({
  columns = { "icon" },
  keymaps = {
    ["<C-h>"] = false,
    ["<M-h>"] = "actions.select_split",
  },
  view_options = {
    show_hidden = true,
  },
})

vim.keymap.set("n", "-", "<CMD>Oil<CR>")

vim.keymap.set("n", "<space>-", require("oil").toggle_float)
