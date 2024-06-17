" Set space as the leader key
let mapleader=" "

" Enable syntax highlighting
syntax on

" Display line numbers and relative line numbers
set number
set relativenumber

" Set tabs and indentation
set tabstop=2
set shiftwidth=2
set expandtab
set autoindent
set smartindent

" Enable line wrapping
set wrap

" Search setting
set incsearch
set ignorecase
set smartcase
set hlsearch

" Interface settings
set cursorline 
set showmatch
set wildmenu
set lazyredraw

" Clipboard setting
set clipboard=unnamedplus

" Enable mouse support
set mouse=a

" Map jk to escape insert mode
inoremap jk <ESC>

" Map <leader>pv to :Ex
nnoremap <leader>pv :Ex<CR>

" Show current mode in the status line
 set laststatus=2
 set statusline=%<%f\ %h%m%r%=%-14.(%l,%c%V%)\ %P\ [%{mode()}]
