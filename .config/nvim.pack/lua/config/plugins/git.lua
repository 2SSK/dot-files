vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  callback = function()
    require("git-blame").setup({
      enabled = true,
      message_template = " <summary> • <date> • <author> • <<sha>>",
      date_format = "%m-%d-%Y %H:%M:%S",
      virtual_text_column = 1,
    })
  end,
})

require("git-conflict").setup()
