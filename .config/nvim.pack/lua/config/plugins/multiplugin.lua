-- Colorizer
require("colorizer").setup({
  user_default_options = { tailwind = true }
})

-- Bufferline
require("bufferline").setup({
  options = {
    diagnostics = "nvim_lsp",
    mode = "tabs",
    show_buffer_close_icons = false,
  },
})

-- Silicon
require("silicon").setup({
  font = "JetBrains Mono Nerd Font=34;Noto Color Emoji=34",
  theme = "Dracula",
  background = "#94e2d5",
  window_title = function()
    return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":t")
  end
})

-- Dressing
vim.api.nvim_create_autocmd("User",{
  pattern = "VeryLazy",
  callback = function() end,
})
