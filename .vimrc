" Fallback editor that follows the desktop theme like every other terminal app.
" nvim is the main editor (~/.config/nvim).

" Options
set encoding=utf-8 fileencoding=utf-8
set number relativenumber numberwidth=2 signcolumn=yes
set mouse=a clipboard=unnamedplus
set ignorecase smartcase showmatch
set tabstop=2 softtabstop=2 shiftwidth=2 expandtab autoindent smartindent breakindent
set nowrap linebreak scrolloff=8 sidescrolloff=8 whichwrap+=<,>,[,],h,l
set splitbelow splitright
set undofile noswapfile nobackup nowritebackup
set updatetime=250 timeoutlen=300
set completeopt=menuone,noselect pumheight=10 shortmess+=c
set backspace=indent,eol,start iskeyword+=- conceallevel=0
set spelllang=en_us,de_de,es_es
set laststatus=2 statusline=%f%=%l/%L

" Colours: the desktop theme (rendered by `theme`), transparent background. vim only handles
" signals on the next keypress, so a timer checks once a second whether the theme changed.
set termguicolors
syntax on
let s:theme = (empty($XDG_STATE_HOME) ? $HOME . '/.local/state' : $XDG_STATE_HOME) . '/desktop/theme/vim.vim'
let s:theme_time = -1
function! s:ApplyTheme(...) abort
	let l:time = getftime(s:theme)
	if l:time == s:theme_time | return | endif
	let s:theme_time = l:time
	if l:time < 0 | colorscheme default | else | execute 'source' fnameescape(s:theme) | endif
	if a:0 | redraw! | endif
endfunction
call s:ApplyTheme()
call timer_start(1000, function('s:ApplyTheme'), {'repeat': -1})

" Beam cursor in insert mode, block elsewhere
let &t_SI = "\e[6 q"
let &t_EI = "\e[2 q"

" Keymaps (leader: Space)
let mapleader = " "
let maplocalleader = " "
nnoremap <Space> <Nop>
vnoremap <Space> <Nop>
inoremap jk <Esc>
nnoremap <expr> k v:count == 0 ? 'gk' : 'k'
nnoremap <expr> j v:count == 0 ? 'gj' : 'j'
nnoremap <leader>nh :noh<CR>
nnoremap <leader>w :w<CR>
nnoremap <leader>sn :noautocmd w<CR>
nnoremap <leader>q :q<CR>
nnoremap x "_x
vnoremap p "_dP
noremap <leader>y "+y
noremap <leader>Y "+Y
nnoremap <C-d> <C-d>zz
nnoremap <C-u> <C-u>zz
nnoremap n nzzzv
nnoremap N Nzzzv
nnoremap <leader>+ <C-a>
nnoremap <leader>- <C-x>
nnoremap <leader>lw :set wrap!<CR>

" Windows, buffers, tabs
nnoremap <C-h> :wincmd h<CR>
nnoremap <C-j> :wincmd j<CR>
nnoremap <C-k> :wincmd k<CR>
nnoremap <C-l> :wincmd l<CR>
nnoremap <Up> :resize -2<CR>
nnoremap <Down> :resize +2<CR>
nnoremap <Left> :vertical resize -2<CR>
nnoremap <Right> :vertical resize +2<CR>
nnoremap <leader>sv <C-w>v
nnoremap <leader>sh <C-w>s
nnoremap <leader>se <C-w>=
nnoremap <leader>sx :close<CR>
nnoremap <Tab> :bnext<CR>
nnoremap <S-Tab> :bprevious<CR>
nnoremap <leader>sb :buffers<CR>:buffer<Space>
nnoremap <leader>x :bdelete<CR>
nnoremap <leader>b :enew<CR>
nnoremap <leader>to :tabnew<CR>
nnoremap <leader>tx :tabclose<CR>
nnoremap <leader>tn :tabn<CR>
nnoremap <leader>tp :tabp<CR>

" File explorer (netrw): Space e, l opens
nnoremap <silent> <leader>e :Lex<CR>
let g:netrw_banner = 0
let g:netrw_liststyle = 3
let g:netrw_browse_split = 4
let g:netrw_altv = 1
let g:netrw_winsize = 25
augroup netrw_setup | autocmd!
	autocmd FileType netrw nmap <buffer> l <CR>
augroup END
