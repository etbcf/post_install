" Vim-Plug requirements
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
call plug#begin()

Plug 'tpope/vim-sensible'
Plug 'tpope/vim-surround'
Plug 'ctrlpvim/ctrlp.vim'
Plug 'vimwiki/vimwiki'
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-fugitive'
Plug 'christoomey/vim-tmux-navigator'
Plug 'christoomey/vim-tmux-runner'
Plug 'nanotech/jellybeans.vim'

call plug#end()



" let
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let mapleader = "\<Space>"

" Make CtrlP use ag for listing the files. Way faster and no useless files.
" Whithout --hidden, it never finds .travis.yml since it starts with a dot.
let g:ctrlp_user_command = 'ag %s -l --hidden --nocolor -g ""'
let g:ctrlp_use_caching = 0



" Colorscheme
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
colorscheme jellybeans



" vimwiki requirements
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
filetype plugin on
syntax on

let g:vimwiki_list = [{'path': '~/Dropbox/vimwiki/',
                      \ 'syntax': 'markdown',
            		      \ 'ext': 'md'}]



" nmap
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
nmap 0 ^
nmap <leader>vr :sp $MYVIMRC<cr>
nmap <leader>so :so $MYVIMRC<cr>
nmap <C-s> :w<cr>
" Pre-populate a split command with the current directory
nmap <leader>v :vnew <C-r>=escape(expand("%:p:h"), ' ') . '/'<cr>

" Edit your vimrc in a new tab
nmap <leader>vi :tabedit ~/.vimrc<cr>

" Copy the entire buffer into the system register
nmap <leader>co ggVG*y

" Move up and down by visible lines if current line is wrapped
nmap j gj
nmap k gk



" imap
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
imap jk <esc>
imap kj <esc>



" set
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set number                      " Display line numbers beside buffer
set nocompatible                " Don't maintain compatibilty with Vi.
set hidden                      " Allow buffer change w/o saving
set lazyredraw                  " Don't update while executing macros
set backspace=indent,eol,start  " Sane backspace behavior
set history=1000                " Remember last 1000 commands
set scrolloff=4                 " Keep at least 4 lines below cursor
set nobackup                    " Don't keep swp files
set expandtab			              " Convert <tab> to spaces (2 or 4)
set tabstop=2			              " Two spaces per tab as default
set shiftwidth=2
set colorcolumn=79
set wildmenu                    " Better? completion on command line
set wildmode=list:full          " What to do when I press 'wildchar'
set cursorline                  " Highlight cursor line



"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
highlight ColorColumn ctermbg=8 guibg=#2a2a2e

" Match separator bg to terminal bg
hi VertSplit ctermfg=white ctermbg=black guifg=#FFFFFF guibg=#000000



" command!
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" command aliases for typoed commands (accidentally holding shift too long)
command! Q q " Bind :Q to :q
command! Qall qall
command! QA qall
command! E e



" autocmd
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
autocmd Filetype help nmap <buffer> q :q<cr>

" automatically rebalance windows on vim resize
autocmd VimResized * :wincmd =



" nnoremap
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
nnoremap <leader>- :wincmd _<cr>:wincmd \|<cr>
nnoremap <leader>= :wincmd =<cr>
