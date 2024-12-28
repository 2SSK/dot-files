return {
  "nvim-telescope/telescope.nvim",
  tag = "0.1.8",
  dependecies = {
    "nvim-lua/plenary.nvim",
    { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
  },

  config = function()
    local keymap = vim.keymap
    local actions = require("telescope.actions")
    local telescope = require("telescope")

    telescope.setup({
      -- Theme
      pickers = {
        find_files = {
          theme = "ivy",
        },
        oldfiles = {
          theme = "ivy",
        },
        live_grep = {
          theme = "ivy",
        },
        grep_string = {
          theme = "ivy",
        },
      },

      -- keymaps
      keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "Find files in CWD" }),
      keymap.set("n", "<leader>fr", "<cmd>Telescope oldfiles<cr>", { desc = "Fuzzy fine recent files" }),
      keymap.set("n", "<leader>fs", "<cmd>Telescope live_grep<cr>", { desc = "Find string in CWD" }),
      keymap.set(
        "n",
        "<leader>fc",
        "<cmd>Telescope grep_string<cr>",
        { desc = "Find string under cursor in CWD" }
      ),

      defaults = {
        path_display = { "smart" },
        mappings = {
          i = {
            ["<C-k>"] = actions.move_selection_previous, -- move to prev result
            ["<C-j>"] = actions.move_selection_next, -- move to next result
          },
        },
      },

      -- Keybind to open config files
      keymap.set("n", "<leader>en", function()
        require("telescope.builtin").find_files({
          cwd = vim.fn.stdpath("config"),
        })
      end),
    })

    require("config.telescope.multigrep").setup()
  end,
}
