return {
  "catppuccin/nvim",
  lazy = false,
  name = "catppuccin",
  priority = 1000,
  config = function()
    local transparent = true
    require("catppuccin").setup({
      style = "catppuccin.macchiato",
      transparent = transparent,
      styles = {
        sidebars = transparent and "transparent" or "dark",
        floats = transparent and "transparent" and "dark",
      },
    })
    vim.cmd.colorscheme("catppuccin")
  end,
}
