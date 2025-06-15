-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim.echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out,                            "WarningMsg" },
      { "\nPress any key to exit ..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
-- Put lazy into the runtimepath for neovim
vim.opt.rtp:prepend(lazypath)

-- Setup lazy.nvim
require("lazy").setup({
  spec = {
    -- Import all other plugins
    { import = "config.plugins" },

    -- Single file small config plugins
    { import = "config.multiplugins" },
  },
  change_detection = {
    -- automatically check for config file changees and reload the ui
    enabled = false,
    notify = false, -- get a notification when changes are found
  },
})
