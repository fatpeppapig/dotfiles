" Vim Plug

if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.vim/plug')

Plug 'rbgrouleff/bclose.vim'
Plug 'kien/ctrlp.vim'
Plug 'scrooloose/nerdtree'
Plug 'ervandew/supertab'
Plug 'vim-syntastic/syntastic'
Plug 'majutsushi/tagbar'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'tpope/vim-fugitive'
Plug 'leafgarland/typescript-vim'
Plug 'pangloss/vim-javascript'
Plug 'mxw/vim-jsx'
Plug 'NLKNguyen/papercolor-theme'

call plug#end()

" Basic Setup

set nocompatible

autocmd! bufwritepost .vimrc source %

filetype off
filetype plugin indent on

syntax on

set mouse=a
set ttymouse=xterm2
set pastetoggle=<f2>

set cursorline
set tabpagemax=80
set nowrap

set tabstop=4
set softtabstop=4
set shiftwidth=4
set shiftround
set expandtab

set smartindent
set laststatus=2
set encoding=utf-8
set relativenumber number
set ofu=syntaxcomplete#Complete
set hlsearch
set title

set nobackup
set nowritebackup
set noswapfile

set tags=tags;/

" macOS clipboard integration

nnoremap v <c-v>
nmap <c-v> :set paste<CR>:r !pbpaste<CR>:set nopaste<CR>
imap <c-v> <Esc>:set paste<CR>:r !pbpaste<CR>:set nopaste<CR>
nmap <c-c> :.w !pbcopy<CR><CR>
vmap <c-c> :w !pbcopy<CR><CR>

set clipboard=unnamed

" Colors
set t_Co=256
set background=light
let g:PaperColor_Theme_Options = {
  \   'theme': {
  \     'default.light': {
  \       'override' : {
  \         'vertsplit_bg' : ['#d0d0d0', '252'],
  \         'vertsplit_fg' : ['#d0d0d0', '252'],
  \         'cursorlinenr_bg' : ['#e4e4e4', '254'],
  \       }
  \     }
  \   }
  \ }
colors PaperColor

nnoremap <silent> <space> :nohlsearch<bar>:echo<cr>

" Buffer navigation

nnoremap bn :bn<cr>
nnoremap bp :bp<cr>
nnoremap bd :Bclose<cr>

" Tab navigation

nnoremap tn :tabn<cr>
nnoremap tp :tabp<cr>

" CTRL-P

let g:ctrlp_max_height = 20
set wildignore+=*.pyc
set wildignore+=*build/*
set wildignore+=*dist/*
set wildignore+=*.egg-info/*
set wildignore+=*/coverage/*
set wildignore+=*/node_modules/*
set wildignore+=*/data/*
map <c-r> :CtrlPClearCache<cr>

" AirLine

let g:airline_detect_modified=1
let g:airline_detect_paste=1
let g:airline#extensions#bufferline#enabled=1
let g:airline#extensions#bufferline#overwrite_variables=1
let g:airline#extensions#syntastic#enabled=1
let g:airline#extensions#tagbar#enabled=1
let g:airline#extensions#csv#enabled=1
let g:airline_theme="papercolor"
let g:airline#extensions#tabline#enabled=1

let g:bufferline_echo=0

" TagBar

let g:tagbar_usearrows = 1
let g:tagbar_autofocus = 1
let g:tagbar_autoclose = 1
nnoremap <f4> :Tagbar<cr>
map <f3> :!ctags -R .<cr>

" NerdTree

map <f1> :NERDTreeToggle<cr>
let NERDTreeQuitOnOpen=1

" Syntastic

let g:syntastic_html_tidy_exec = 'tidy5'
let g:syntastic_quiet_messages = { 'regex': 'Cannot find package' }
let g:syntastic_typescript_checkers = ['tslint']
