-- Description: Plugins with minimal configuration
return {
  -- Colorscheme
  {
    "folke/tokyonight.nvim",
    priority = 1000,
    config = function()
      require("tokyonight").setup({
        style = "night",
        transparent = true,
        styles = {
          sidebars = "transparent",
          floats = "transparent",
        },
      })
      vim.cmd.colorscheme("tokyonight")
    end,
  },

  -- Copilot plugin
  { "github/copilot.vim" },
  --
  -- Vim-move plugin
  { "matze/vim-move" },
  --
  -- tmux movement
  { "christoomey/vim-tmux-navigator" },
  --
  -- Colorizer
  {
    "NvChad/nvim-colorizer.lua",
    opts = {
      user_default_options = {
        tailwind = true,
      },
    },
  },

  -- which key
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    init = function()
      vim.o.timeout = true
      vim.o.timeoutlen = 500
    end,
  },

  -- UI enhancement plugin
  {
    "stevearc/dressing.nvim",
    event = "VeryLazy",
  },

  -- Tab bar
  {
    "akinsho/bufferline.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    version = "*",
    opts = {
      options = {
        mode = "tabs",
      },
    },
  },
}
