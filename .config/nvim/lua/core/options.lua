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
opt.signcolumn = "yes"

opt.backspace = "indent,eol,start"

opt.clipboard:append("unnamedplus")

opt.splitright = true
opt.splitbelow = true

-- Folding: by LSP or treesitter (set per buffer), everything open by default
vim.o.foldlevel = 99
vim.o.foldlevelstart = 99
vim.o.foldcolumn = "0"
