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
nnoremap <leader>ee :NERDTreeToggle<CR> 
nnoremap <leader>ff :Files<CR>         
nnoremap <leader>pv :Ex<CR>

set laststatus=2

" Set colorscheme to gruvbox and make it transparent
colorscheme retrobox
set background=dark

" Vim-Plug configuration
call plug#begin('~/.vim/plugged')

" Example Plugins
Plug 'sheerun/vim-polyglot'  " Language packs for syntax highlighting
Plug 'scrooloose/nerdtree'   " File explorer
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } } " Fuzzy finder
Plug 'junegunn/fzf.vim'       " FZF integration
Plug 'tpope/vim-fugitive'     " Git commands in Vim
Plug 'airblade/vim-gitgutter' " Show git diff in gutter
Plug 'preservim/nerdcommenter' " Commenting utility
Plug 'itchyny/lightline.vim'  " Lightweight statusline

call plug#end()


  " Set retro-style cursor with block in normal mode and bar in insert mode
  set guicursor=n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50

