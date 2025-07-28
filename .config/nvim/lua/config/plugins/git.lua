return {
  {
    "tpope/vim-fugitive",
  },
  {
    "f-person/git-blame.nvim",
    event = "VeryLazy",
    opts = {
      enabled = true, -- if you want to enable the plugin
      message_template = " <summary> • <date> • <author> • <<sha>>", -- template for the blame message, check the Message template section for more options
      date_format = "%m-%d-%Y %H:%M:%S", -- template for the date, check Date format section for more options
      virtual_text_column = 1, -- virtual text start column, check Start virtual text at column section for more options
    },
  },
  {
    "akinsho/git-conflict.nvim",
    version = "*",
    config = true,
  },
  {
    "sindrets/diffview.nvim",
    config = function()
      local keymap = vim.api.nvim_set_keymap
      local opts = { noremap = true, silent = true }

      -- Open Diffview to compare the working directory with the last commit
      keymap("n", "<leader>do", ":DiffviewOpen<CR>", opts)

      -- Open Diffview with a specific commit or branch for comparison
      keymap("n", "<leader>dc", ":DiffviewOpen ", opts) -- Note: Requires input after pressing the keys

      -- Close Diffview and return to the normal editor view
      keymap("n", "<leader>dx", ":DiffviewClose<CR>", opts)

      -- Toggle the file panel (list of changed files) on and off
      -- Example Keymap: Press `<leader>df` to toggle the file panel
      keymap("n", "<leader>df", ":DiffviewToggleFiles<CR>", opts)

      -- Focus on the file panel to navigate between changed files

      -- Example Keymap: Press `<leader>dfc` to focus on the file panel
      keymap("n", "<leader>dfc", ":DiffviewFocusFiles<CR>", opts)

      -- Refresh the Diffview window to reflect the latest changes
      -- Example Keymap: Press `<leader>dr` to refresh Diffview
      keymap("n", "<leader>dr", ":DiffviewRefresh<CR>", opts)

      -- Navigate to the next file in the Diffview
      -- Example Keymap: Press `]d` to go to the next file
      keymap("n", "]d", ":DiffviewNextFile<CR>", opts)

      -- Navigate to the previous file in the Diffview
      -- Example Keymap: Press `[d` to go to the previous file
      keymap("n", "[d", ":DiffviewPrevFile<CR>", opts)

      -- Open the file history view to see the commit history for a file or directory
      -- Example Keymap: Press `<leader>dh` to open the file history
      keymap("n", "<leader>dh", ":DiffviewFileHistory<CR>", opts)

      -- Stage the current file in the Diffview
      -- Example Keymap: Press `<leader>ds` to stage the current file
      keymap("n", "<leader>ds", ":DiffviewStageFile<CR>", opts)

      -- Unstage the current file in the Diffview
      -- Example Keymap: Press `<leader>du` to unstage the current file
      keymap("n", "<leader>du", ":DiffviewUnstageFile<CR>", opts)
      -- Example Keymap: Press `<leader>dsa` to stage all files
      keymap("n", "<leader>dsa", ":DiffviewStageAllFiles<CR>", opts)

      -- Unstage all files in the Diffview
      -- Example Keymap: Press `<leader>dua` to unstage all files
      keymap("n", "<leader>dua", ":DiffviewUnstageAllFiles<CR>", opts)
    end,
  },
}

-- Git Conflict COMMANDS :
-- GitConflictChooseOurs — Select the current changes.
-- GitConflictChooseTheirs — Select the incoming changes.
-- GitConflictChooseBoth — Select both changes.
-- GitConflictChooseNone — Select none of the changes.
-- GitConflictNextConflict — Move to the next conflict.
-- GitConflictPrevConflict — Move to the previous conflict.
-- GitConflictListQf — Get all conflict to quickfix
