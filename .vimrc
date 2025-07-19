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
nnoremap <leader>ww :wa!<CR> 
nnoremap <leader>q :q!<CR> 
nnoremap <leader>wq :wqa!<CR> 
nnoremap <leader>ee :NERDTreeToggle<CR> 
let NERDTreeShowHidden=1
nnoremap <leader>ff :Files<CR>         
nnoremap <leader>pv :Ex<CR>

set laststatus=2

" Set colorscheme to gruvbox and make it transparent
colorscheme blue
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
" Plug 'itchyny/lightline.vim'  " Lightweight statusline
Plug 'neoclide/coc.nvim', {'branch':'release'}
Plug 'jiangmiao/auto-pairs'
Plug 'kana/vim-textobj-user'
Plug 'tpope/vim-surround'
Plug 'kana/vim-textobj-function'
Plug 'glts/vim-textobj-comment'

call plug#end()

" Set retro-style cursor with block in normal mode and bar in insert mode
set guicursor=n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50

" Use tab for trigger completion
inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ CheckBackspace() ? "\<TAB>" :
      \ coc#refresh()

function! CheckBackspace() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" Use K to show documentation
nnoremap <silent> K :call CocActionAsync('doHover')<CR>

" Go to definition
nnoremap <silent> gd <Plug>(coc-definition)

" Formatting
nnoremap <silent> <leader>f  :call CocAction('format')<CR>gruvbox

