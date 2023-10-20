"
" (C) 2023 Stefan Greve
"

let mapleader=" "

call plug#begin('~/AppData/Local/nvim/plugged')
    Plug 'sheerun/vim-polyglot'
    Plug 'scrooloose/NERDTree'
    Plug 'jiangmiao/auto-pairs'
    Plug 'editorconfig/editorconfig-vim'
    Plug 'tmhedberg/SimpylFold'
    Plug 'neoclide/coc.nvim', {'branch': 'release'}
call plug#end()

syntax on
filetype on
set nocompatible
set encoding=utf-8
set expandtab
set smarttab
set shiftwidth=4
set tabstop=4
set lbr
set tw=260
set ai
set si
set number
set ruler
set hlsearch
set magic
set nobackup
set nowb
set noswapfile
set lazyredraw
set foldmethod=indent
set foldlevel=99
set clipboard^=unnamed,unnamedplus

" CoC specific settings
set hidden
set nobackup
set nowritebackup
set cmdheight=2
set updatetime=200
set shortmess+=c

set statusline=
set statusline+=%1*\ %n\ %*     " buffer number
set statusline+=%5*%{&ff}%*     " file format
set statusline+=%3*%y%*         " file type
set statusline+=%4*\ %<%F%*     " full file path
set statusline+=%2*%m%*         " modified flag
set statusline+=%1*%=%5l%*      " current line no
set statusline+=%2*/%L%*        " total no of lines
set statusline+=%1*%4v\ %*      " virtual column no
set statusline+=%2*0x%04B\ %*   " character under cursor

if has('termguicolors')
    set termguicolors
endif

" enable auto-completion
set wildmode=longest,list,full
" disable comment continuation
autocmd BufNewFile,Bufread * setlocal formatoptions-=cro
" return to last modified line after opening a file
au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
" automatically delete all trailing white spaces
autocmd BufWritePre * %s/\s\+$//e

" check spelling
map <leader>o :setlocal spell! spelllang=en_us<CR>

" move focuc between panes
set splitbelow splitright
map <C-h> <C-w>h
map <C-j> <C-w>j
map <C-k> <C-w>k
map <C-l> <C-w>l

" always show signcolumn
if has('nvim-0.5.0') || has('patch-8.1.1564')
    set signcolumn=number
else
    set signcolumn=yes
endif

" tab completion
inoremap <silent><expr> <Tab> pumvisible() ? "\<C-n>" : CheckBackspace() ? "\<TAB>" : coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

function! CheckBackspace() abort
    let col = col('.') - 1
    return !col || getline('.')[col - 1] =~# '\s'
endfunction

" trigger completion
if has('nvim')
    inoremap <silent><expr> <c-space> coc#refresh()
else
    inoremap <silent><expr> <c-@> coc#refresh()
endif

" select first on enter
inoremap <silent><expr> <cr> pumvisible() ? coc#_select_confirm() : "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

" show documentation
nnoremap <silent> K : call ShowDocumentation()<CR>

function! ShowDocumentation()
    if CocAction('hasProvider', 'hover')
        call CocActionAsync('doHover')
    else
        call feedkeys('K', 'in')
    endif
endfunction

" placeholder guide
nnoremap ,, <Esc>/<++><Enter>"_c4l

" python
nnoremap <Space> za
let NERDTreeIgnore=['\.pyc$', '\~$']

" misc
autocmd CursorHold * silent call CocActionAsync('highlight')
