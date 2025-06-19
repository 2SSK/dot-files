return {
    "folke/tokyonight.nvim",
    name = "tokyonight",
    priority = 1000,
    config = function()
      local transparent = false
      require("tokyonight").setup({
        transparent = transparent
      })
      vim.cmd([[colorscheme tokyonight]])
    end
}
