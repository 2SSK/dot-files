-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
	if vim.v.shell_error ~= 0 then
		vim.api.nvim_echo({
			{ "Failed to clone lazy.nvim:\n", "ErrorMsg" },
			{ out, "WarningMsg" },
			{ "\nPress any key to exit ..." },
		}, true, {})
		vim.fn.getchar()
		os.exit(1)
	end
end
-- Put lazy into the runtimepath for neovim
vim.opt.rtp:prepend(lazypath)

-- The tracked lockfile pins plugin versions. In a read-only checkout (the test VM's share),
-- lazy.nvim keeps its own copy in the state dir, seeded from the tracked one.
local lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json"
if vim.fn.filewritable(lockfile) ~= 1 then
	local copy = vim.fn.stdpath("state") .. "/lazy-lock.json"
	if vim.fn.filereadable(copy) == 0 then
		vim.fn.mkdir(vim.fn.fnamemodify(copy, ":h"), "p")
		vim.fn.writefile(vim.fn.readfile(lockfile), copy)
	end
	lockfile = copy
end

-- Setup lazy.nvim
require("lazy").setup({
	lockfile = lockfile,
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
	ui = {
		border = "rounded",
		backdrop = 100,
	},
})
