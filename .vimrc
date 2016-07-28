" Setup

set nocompatible

autocmd! bufwritepost .vimrc source %

filetype off
filetype plugin indent on

call pathogen#infect()
call pathogen#helptags()

syntax on

set mouse=a
set ttymouse=xterm2
set pastetoggle=<f2>

nnoremap v <c-v>
nmap <c-v> :set paste<CR>:r !pbpaste<CR>:set nopaste<CR>
imap <c-v> <Esc>:set paste<CR>:r !pbpaste<CR>:set nopaste<CR>
nmap <c-c> :.w !pbcopy<CR><CR>
vmap <c-c> :w !pbcopy<CR><CR>

set clipboard=unnamed

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
set number
set makeprg=python\ %
set ofu=syntaxcomplete#Complete
set guifont=Menlo\ Regular:h12
set hlsearch
set title

set nobackup
set nowritebackup
set noswapfile

set tags=tags;/

" let &colorcolumn=join(range(81,999),",")

" Colors and transparency

colorscheme lucius
LuciusLight

if &term =~ "xterm.*"
	let &t_ti = &t_ti . "\e[?2004h"
	let &t_te = "\e[?2004l" . &t_te
	function! XTermPasteBegin(ret)
		set pastetoggle=<Esc>[201~
		set paste
		return a:ret
	endfunction
	map <expr> <Esc>[200~ XTermPasteBegin("i")
	imap <expr> <Esc>[200~ XTermPasteBegin("")
	cmap <Esc>[200~ <nop>
	cmap <Esc>[201~ <nop>
endif

" (No)Highlight search and whitespaces at the end of line

nnoremap <silent> <space> :nohlsearch<bar>:echo<cr>

" highlight WhitespaceEOL ctermbg=red guibg=red
" match WhitespaceEOL /\s\+$/

" Buffer navigation

nnoremap bn :bn<cr>
nnoremap bp :bp<cr>
nnoremap bd :Bclose<cr>

" Tab navigation

nnoremap tn :tabn<cr>
nnoremap tp :tabp<cr>

" CTRL-P Setup

let g:ctrlp_max_height = 20
set wildignore+=*.pyc
set wildignore+=*build/*
set wildignore+=*dist/*
set wildignore+=*.egg-info/*
set wildignore+=*/coverage/*
map <c-r> :CtrlPClearCache<cr>

" NETRW Setup

let g:netrw_browse_split=3
let g:netrw_liststyle=1
let g:netrw_banner=0
let g:netrw_altv=1

" AirLine Setup

let g:airline_left_sep=''
let g:airline_right_sep=''
let g:airline_detect_modified=1
let g:airline_detect_paste=1
let g:airline#extensions#bufferline#enabled=1
let g:airline#extensions#bufferline#overwrite_variables=1
let g:airline#extensions#syntastic#enabled=1
let g:airline#extensions#tagbar#enabled=1
let g:airline#extensions#csv#enabled=1
let g:airline_theme="lucius"
let g:airline#extensions#tabline#enabled=1

let g:bufferline_echo=0

" TagBar Setup

let g:tagbar_usearrows = 1
let g:tagbar_autofocus = 1
let g:tagbar_autoclose = 1
nnoremap <f4> :Tagbar<cr>
map <f3> :!ctags -R .<cr>

" go to defn of tag under the cursor
fun! MatchCaseTag()
    let ic = &ic
    set noic
    try
        exe 'tjump ' . expand('<cword>')
    finally
       let &ic = ic
    endtry
endfun
nnoremap <silent> <c-]> :call MatchCaseTag()<cr>

" NerdTree Setup

map <f1> :NERDTreeToggle<cr>
let NERDTreeQuitOnOpen=1

" Syntastic

" let g:syntastic_python_checkers = ['flake8']
" let g:syntastic_flake8_args="--max-line-length=120"
" let g:flake8_max_line_length=120
" let g:syntastic_flake8_max_line_length=120

" Vim Grep

map <c-g> :vimgrep /<C-R>"/gj ./**/*.%:e
set fillchars+=vert:\ 
