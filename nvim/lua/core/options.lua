local opt = vim.opt

opt.relativenumber = true
opt.number = true

opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.autoindent = true

opt.wrap = true

opt.ignorecase = true
opt.smartcase = true

opt.cursorline = false

opt.termguicolors = true
opt.background = "dark"
opt.signcolumn = "yes"

opt.backspace = "indent,eol,start"

opt.clipboard:append("unnamedplus")

opt.splitright = true
opt.splitbelow = true

-- auto save on text change, only for normal buffers
-- vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
--   callback = function()
--     if vim.bo.buftype == "" and vim.fn.expand('%') ~= '' then
--       -- only write if it's a normal buffer with a file name
--       vim.cmd("silent write")
--     end
--   end,
-- })

opt.swapfile = false
