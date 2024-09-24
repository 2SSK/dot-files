let mapleader=" "

syntax on

set number
set relativenumber

set tabstop=2
set shiftwidth=2
set expandtab
set autoindent
set smartindent

set wrap

set incsearch
set ignorecase
set smartcase
set hlsearch

set cursorline 
set showmatch
set wildmenu
set lazyredraw

set clipboard=unnamedplus

set mouse=a

inoremap jk <ESC>

nnoremap <leader>pv :Ex<CR>

set laststatus=2

" Change the thickness of the cursor in insert mode
set guicursor=n-v-c:block,i-ci-ve:ver20,r-cr-o:hor20

" Set colorscheme to gruvbox and make it transparent
colorscheme retrobox
set background=dark

" Enable transparent background
hi Normal guibg=NONE ctermbg=NONE
hi LineNr guibg=NONE ctermbg=NONE
hi SignColumn guibg=NONE ctermbg=NONE
hi EndOfBuffer guibg=NONE ctermbg=NONE
