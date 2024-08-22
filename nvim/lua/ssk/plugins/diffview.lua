return {
  "sindrets/diffview.nvim",
  config = function()
    local keymap = vim.api.nvim_set_keymap
    local opts = { noremap = true, silent = true }

    -- Keybindings for Diffview

    -- Open Diffview to compare the working directory with the last commit
    -- Usage: `:DiffviewOpen`
    -- Example Keymap: Press `<leader>do` to open Diffview
    keymap("n", "<leader>do", ":DiffviewOpen<CR>", opts)

    -- Open Diffview with a specific commit or branch for comparison
    -- Usage: `:DiffviewOpen {commit/branch}`
    -- Example Keymap: Press `<leader>dc` to open Diffview with a prompt for a commit/branch
    keymap("n", "<leader>dc", ":DiffviewOpen ", opts) -- Note: Requires input after pressing the keys

    -- Close Diffview and return to the normal editor view
    -- Usage: `:DiffviewClose`
    -- Example Keymap: Press `<leader>dx` to close Diffview
    keymap("n", "<leader>dx", ":DiffviewClose<CR>", opts)

    -- Toggle the file panel (list of changed files) on and off
    -- Usage: `:DiffviewToggleFiles`
    -- Example Keymap: Press `<leader>df` to toggle the file panel
    keymap("n", "<leader>df", ":DiffviewToggleFiles<CR>", opts)

    -- Focus on the file panel to navigate between changed files
    -- Usage: `:DiffviewFocusFiles`
    -- Example Keymap: Press `<leader>dfc` to focus on the file panel
    keymap("n", "<leader>dfc", ":DiffviewFocusFiles<CR>", opts)

    -- Refresh the Diffview window to reflect the latest changes
    -- Usage: `:DiffviewRefresh`
    -- Example Keymap: Press `<leader>dr` to refresh Diffview
    keymap("n", "<leader>dr", ":DiffviewRefresh<CR>", opts)

    -- Navigate to the next file in the Diffview
    -- Usage: `:DiffviewNextFile`
    -- Example Keymap: Press `]d` to go to the next file
    keymap("n", "]d", ":DiffviewNextFile<CR>", opts)

    -- Navigate to the previous file in the Diffview
    -- Usage: `:DiffviewPrevFile`
    -- Example Keymap: Press `[d` to go to the previous file
    keymap("n", "[d", ":DiffviewPrevFile<CR>", opts)

    -- Open the file history view to see the commit history for a file or directory
    -- Usage: `:DiffviewFileHistory {file/path}`
    -- Example Keymap: Press `<leader>dh` to open the file history
    keymap("n", "<leader>dh", ":DiffviewFileHistory<CR>", opts)

    -- Stage the current file in the Diffview
    -- Usage: `:DiffviewStageFile`
    -- Example Keymap: Press `<leader>ds` to stage the current file
    keymap("n", "<leader>ds", ":DiffviewStageFile<CR>", opts)

    -- Unstage the current file in the Diffview
    -- Usage: `:DiffviewUnstageFile`
    -- Example Keymap: Press `<leader>du` to unstage the current file
    keymap("n", "<leader>du", ":DiffviewUnstageFile<CR>", opts)

    -- Stage all files in the Diffview
    -- Usage: `:DiffviewStageAllFiles`
    -- Example Keymap: Press `<leader>dsa` to stage all files
    keymap("n", "<leader>dsa", ":DiffviewStageAllFiles<CR>", opts)

    -- Unstage all files in the Diffview
    -- Usage: `:DiffviewUnstageAllFiles`
    -- Example Keymap: Press `<leader>dua` to unstage all files
    keymap("n", "<leader>dua", ":DiffviewUnstageAllFiles<CR>", opts)
  end,
}
