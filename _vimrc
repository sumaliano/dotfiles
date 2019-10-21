" This is Joel Silva's vimrc standalone
" Sun 20 Oct 2019 09:47:40 PM CEST

" VIM SETTINGS {{{1
set nocompatible
set mouse=a
" set hidden " allow unsaved background buffers and remember marks/undo for them
set history=1000
set expandtab "use spaces instead tabs

set tabstop=4
set shiftwidth=4
set softtabstop=4
set autoindent

set laststatus=2
set showmatch " Show matching brackets when text indicator is over them
set hlsearch " Highlight search results
set ignorecase smartcase " make searches case-sensitive only if they contain upper-case characters
set incsearch " incremental search highlight
set cursorline " highlight current line
set cmdheight=1 " Height of the command bar
set switchbuf=useopen
set showtabline=1
set shell=bash 
set scrolloff=3 " keep more context when scrolling off the end of a buffer
set showcmd " display incomplete commands
filetype plugin indent on " Also load indent files, to automatically do language-dependent indenting.

set omnifunc=syntaxcomplete#Complete
set completefunc=syntaxcomplete#Complete
set path+=** " Search into subfolders

set timeout timeoutlen=1000 ttimeoutlen=100 " Fix slow O inserts
set nojoinspaces " Insert only one space when joining lines that contain sentence-terminating punctuation like `.`.
set ruler "Always show current position
set noerrorbells visualbell t_vb= tm=500 " No annoying sound on errors
set backspace=indent,eol,start  " more powerful backspacing

"set autochdir " Automaitcally change to current directory
set lazyredraw " Don't redraw while executing macros (good performance config)
" set listchars=trail:·,tab:▸\ ,eol:¬
set listchars=trail:▓,tab:▒░,eol:¬

set nowrap
set colorcolumn=80
set number relativenumber
set numberwidth=2

set wildmenu " make tab completion for files/buffers act like bash
set wildmode=longest:full,full " use emacs-style tab completion when selecting files, etc
set wildchar=<Tab>
set wildcharm=<C-Z>

" set undofile
set backupdir=~/.vim/tmp
set directory=~/.vim/tmp
set undodir=~/.vim/tmp

let mapleader = " "

" The Silver Searcher
if executable('ag')
    " Use ag over grep
    set grepprg=ag\ --nogroup\ --nocolor

    " Use ag in CtrlP for listing files. Lightning fast and respects .gitignore
    let g:ctrlp_user_command = 'ag %s -l --nocolor -g ""'

    " ag is fast enough that CtrlP doesn't need to cache
    let g:ctrlp_use_caching = 0
endif


" COLOR {{{1
" if !has('gui_running')
"     if $TERM == "st-256color" || $TERM == "xterm-256color" || $TERM == "screen-256color" || $COLORTERM == "gnome-terminal"
"         set t_Co=256
"     elseif has("terminfo")
"         set t_Co=8
"         set t_Sf=[3%p1%dm
"         set t_Sb=[4%p1%dm
"     else
"         set t_Co=8
"         set t_Sf=[3%dm
"         set t_Sb=[4%dm
"     endif
" endif

" switch syntax highlighting on, when the terminal has colors
if &t_Co > 2 || has("gui_running")
    syntax enable
endif

if (has("nvim"))
    let $NVIM_TUI_ENABLE_TRUE_COLOR=1
endif

if (has("termguicolors"))
    set termguicolors
endif

colorscheme suma

" GUI {{{1
if has("gui")
    " set the gui options to:
    "   g: grey inactive menu items
    "   m: display menu bar
    "   r: display scrollbar on right side of window
    "   b: display scrollbar at bottom of window
    "   t: enable tearoff menus on Win32
    "   T: enable toolbar on Win32
    set guioptions=g
    "set guioptions-=T
    "set guioptions+=e
    "set guitablabel=%M\ %t
    set guifont=Consolas\ 14
    " set guifont=Fira\ Code\ 10
    " set guifont=Input\ Mono\ Regular\ 10
    " set guifont=Inconsolata\ 11

    nnoremap <leader>sm :if &go=~#'m'<Bar>set go-=m<Bar>else<Bar>set go+=m<Bar>endif<CR>
    nnoremap <leader>st :if &go=~#'T'<Bar>set go-=T<Bar>else<Bar>set go+=T<Bar>endif<CR>
    nnoremap <leader>sr :if &go=~#'r'<Bar>set go-=r<Bar>else<Bar>set go+=r<Bar>endif<CR>
endif

" AUTOCMDS {{{1
if has ('autocmd') " Remain compatible with earlier versions
    augroup vimrcEx
        "Clear all autocmds in the group
        autocmd!

        autocmd BufRead,BufNewFile *.gle set filetype=gle
        autocmd BufRead,BufNewFile *.m,*.oct set filetype=octave
        autocmd BufRead,BufNewFile *.sage,*.spyx,*.pyx setfiletype=python
        autocmd BufRead,BufNewFile *.tex set filetype=tex
        autocmd BufRead,BufNewFile *.ino set filetype=arduino
        autocmd BufRead,BufNewFile *.md set filetype=markdown
        autocmd BufRead,BufNewFile *.jira set filetype=confluencewiki

        autocmd Filetype tex setlocal colorcolumn=0
        autocmd Filetype tex setlocal makeprg='make'
        autocmd Filetype tex syntax spell toplevel

        autocmd Filetype mail setlocal nofoldenable
        autocmd Filetype mail setlocal nowrap formatoptions=tcqjnawr textwidth=72
        " Remore trailling spaces
        autocmd Filetype mail :call StripTrailingWhitespace()
        " Jump to last cursor position unless it's invalid or in an event handler
        autocmd BufReadPost *
                    \ if line("'\"") > 0 && line("'\"") <= line("$") |
                    \   exe "normal g`\"" |
                    \ endif
        " For ruby, autoindent with two spaces, always expand tabs
        autocmd FileType tex,ruby,haml,eruby,yaml,html,sass,cucumber
                    \ set ai sw=2 sts=2 ts=2 et
        autocmd FileType python,javascript set sw=4 sts=4 ts=4 et
        autocmd FileType python set smartindent smarttab

        autocmd Syntax c,cpp setlocal foldmethod=syntax
        autocmd Syntax c,cpp normal zR
        autocmd Filetype c,cpp set colorcolumn=100
        autocmd Syntax cpp set syntax=cpp.doxygen
        autocmd FileType c set makeprg=gcc\ -o\ %<\ %
        autocmd FileType cpp set makeprg=g++\ -std=c++11\ -o\ %<\ %


        "   Leave the return key alone when in command line windows, since it's
        "   used to run commands there.
        autocmd! CmdwinEnter * :unmap <cr>
        autocmd! CmdwinLeave * :call MapCR()
        "   Automaitcally change to current directory
        " autocmd BufEnter * silent! lcd %:p:h
        autocmd Filetype vim setlocal foldmethod=marker

        " autocmd BufWritePre *.cpp,*.hpp,*.c,*.h,*.cc,*.hh :RemoveTrailingSpaces " remore trailling spaces
    augroup END

    " augroup autoformat
    "     autocmd!
    "     autocmd FileType xml noremap <leader>= :FormatXml<Cr>
    "     autocmd FileType html noremap <leader>= :FormatHtml<Cr>
    "     autocmd FileType python noremap <leader>= :FormatPython<Cr>
    "     autocmd FileType c,cpp noremap <leader>= :FormatCpp<Cr>
    " augroup END

    augroup vimrc     " Source vim configuration upon save
        autocmd!
        autocmd! BufWritePost ~/.vimrc-standalone source %
    augroup END

    augroup numbertoggle
        autocmd!
        autocmd InsertLeave * set relativenumber
        autocmd InsertEnter   * set norelativenumber
    augroup END

    " Transparent editing of GnuPG-encrypted files
    " Based on a solution by Wouter Hanegraaff
    augroup encrypted
        autocmd!
        " First make sure nothing is written to ~/.viminfo while editing
        " an encrypted file.
        autocmd BufReadPre,FileReadPre *.gpg,*.asc set viminfo=
        " We don't want a swap file, as it writes unencrypted data to disk.
        autocmd BufReadPre,FileReadPre *.gpg,*.asc set noswapfile
        " Switch to binary mode to read the encrypted file.
        autocmd BufReadPre,FileReadPre *.gpg set bin
        autocmd BufReadPre,FileReadPre *.gpg,*.asc let ch_save = &ch|set ch=2
        autocmd BufReadPost,FileReadPost *.gpg,*.asc
                    \ '[,']!gpg --decrypt 2>/dev/null
        " Switch to normal mode for editing
        autocmd BufReadPost,FileReadPost *.gpg set nobin
        autocmd BufReadPost,FileReadPost *.gpg,*.asc let &ch = ch_save|unlet ch_save
        autocmd BufReadPost,FileReadPost *.gpg,*.asc
                    \ execute ":doautocmd BufReadPost " . expand("%:r")

        " Convert all text to encrypted text before writing
        autocmd BufWritePre,FileWritePre *.gpg set bin
        autocmd BufWritePre,FileWritePre *.gpg
                    \ '[,']!gpg --default-recipient-self -e 2>/dev/null
        autocmd BufWritePre,FileWritePre *.asc
                    \ '[,']!gpg --default-recipient-self -e -a 2>/dev/null
        " Undo the encryption so we are back in the normal text, directly
        " after the file has been written.
        autocmd BufWritePost,FileWritePost *.gpg,*.asc u
    augroup END

    augroup quickfix
        autocmd!
        " Automatically open, but do not go to (if there are errors) the quickfix /
        " location list window, or close it when is has become empty.
        "
        " Note: Must allow nesting of autocmds to enable any customizations for quickfix
        " buffers.
        " Note: Normally, :cwindow jumps to the quickfix window if the command opens it
        " (but not if it's already open). However, as part of the autocmd, this doesn't
        " seem to happen.
        autocmd QuickFixCmdPost [^l]* nested cwindow
        autocmd QuickFixCmdPost    l* nested lwindow

        autocmd FileType qf call AdjustWindowHeight(3, 10)
        function! AdjustWindowHeight(minheight, maxheight)
            let l = 1
            let n_lines = 0
            let w_width = winwidth(0)
            while l <= line('$')
                " number to float for division
                let l_len = strlen(getline(l)) + 0.0
                let line_width = l_len/w_width
                let n_lines += float2nr(ceil(line_width))
                let l += 1
            endw
            exe max([min([n_lines, a:maxheight]), a:minheight]) . "wincmd _"
        endfunction
    augroup END
endif " has autocmd }}}

" STATUS LINE {{{1
let g:currentmode={
            \ 'n'  : 'Normal ',
            \ 'no' : 'N·Operator Pending ',
            \ 'v'  : 'Visual ',
            \ 'V'  : 'V·Line ',
            \ '' : 'V·Block ',
            \ 's'  : 'Select ',
            \ 'S'  : 'S·Line ',
            \ '' : 'S·Block ',
            \ 'i'  : 'Insert ',
            \ 'R'  : 'Replace ',
            \ 'Rv' : 'V·Replace ',
            \ 'c'  : 'Command ',
            \ 'cv' : 'Vim Ex ',
            \ 'ce' : 'Ex ',
            \ 'r'  : 'Prompt ',
            \ 'rm' : 'More ',
            \ 'r?' : 'Confirm ',
            \ '!'  : 'Shell ',
            \ 't'  : 'Terminal '
            \}

" Find out current buffer's size and output it.
function! FileSize()
    let bytes = getfsize(expand('%:p'))
    if (bytes >= 1024)
        let kbytes = bytes / 1024
    endif
    if (exists('kbytes') && kbytes >= 1024)
        let mbytes = kbytes / 1024
    endif

    if bytes <= 0
        return '0'
    endif

    if (exists('mbytes'))
        return mbytes . '_MB '
    elseif (exists('kbytes'))
        return kbytes . '_KB '
    else
        return bytes . '_B '
    end
endfunction

function! ReadOnly()
    if &readonly || !&modifiable
        return 'RO'
    else
        return ''
    endif
endfunction

function! GitInfo()
    let git = fugitive#head()
    if git != ''
        return 'B '.fugitive#head()
    else
        return ''
    endif
endfunction

function! InsertStatuslineColor(mode)
    if a:mode == 'i'
        hi StatusLine ctermbg=003     ctermfg=235
    elseif a:mode == 'r'
        hi StatusLine ctermbg=001     ctermfg=233
    else
        hi StatusLine ctermbg=002     ctermfg=235
    endif
endfunction

function! s:fzf_statusline()
    " Override statusline as you like
endfunction

au InsertEnter * call InsertStatuslineColor(v:insertmode)
au InsertLeave * hi StatusLine ctermbg=234     ctermfg=007  gui=bold

" default the statusline to green when entering Vim
hi StatusLine ctermbg=234     ctermfg=007  gui=bold

set statusline=
" set statusline+=%0*\ %{toupper(g:currentmode[mode()])}   " Current mode
set statusline+=%1*\ [%n]                              " buffernr
" set statusline+=%2*%{GitInfo()}\                         " Git Branch name
set statusline+=%3*\ %<%F\ %{ReadOnly()}\ %m\ %r\ %w\    " File+path
"set statusline+=%4*\ %#warningmsg#
"set statusline+=%4*\ %{SyntasticStatuslineFlag()}       " Syntastic errors
"set statusline+=%4*\ %*
set statusline+=%5*\ %=                                  " Space
set statusline+=%6*\ %y\                                 " FileType
set statusline+=%7*\ %{(&fenc!=''?&fenc:&enc)}\[%{&ff}]\ " Encoding & Fileformat
set statusline+=%8*\ %-3(%{FileSize()}%)                 " File size
set statusline+=%0*\ %3p%%\ \ %l:%2c\                 " Rownumber/total (%)

hi User1 ctermfg=009 ctermbg=236 cterm=bold guifg=#a16946 guibg=#303030
hi User2 ctermfg=007 ctermbg=236            guifg=#d8d8d8 guibg=#303030
hi User3 ctermfg=003 ctermbg=238            guifg=#f7ca88 guibg=#444444
hi User4 ctermfg=007 ctermbg=238            guifg=#d8d8d8 guibg=#444444
hi User5 ctermfg=214 ctermbg=238            guifg=#ffaf00 guibg=#444444
hi User6 ctermfg=007 ctermbg=238            guifg=#d8d8d8 guibg=#444444
hi User7 ctermfg=007 ctermbg=238            guifg=#d8d8d8 guibg=#444444
hi User8 ctermfg=007 ctermbg=236            guifg=#d8d8d8 guibg=#303030

" MAPPINGS {{{1
" if has('nvim')
" else
"     " Alt key  not working in gnome terminal workaround
"     let c='a'
"     while c <= 'z'
"         exec "set <A-".c.">=\e".c
"         exec "imap \e".c." <A-".c.">"
"         let c = nr2char(1+char2nr(c))
"     endw
"     set timeout ttimeoutlen=50
" endif

" Move a line of text using ALT+[jk] {{{2
nnoremap <A-j> :m .+1<CR>==
nnoremap <A-k> :m .-2<CR>==
nnoremap <A-h> <<
nnoremap <A-l> >>
inoremap <A-j> <Esc>:m .+1<CR>==gi
inoremap <A-k> <Esc>:m .-2<CR>==gi
inoremap <A-h> <Esc><<`]a
inoremap <A-l> <Esc>>>`]a
vnoremap <A-j> :m '>+1<CR>gv=gv
vnoremap <A-k> :m '<-2<CR>gv=gv
vnoremap <A-h> <gv
vnoremap <A-l> >gv
if has("mac") || has("macunix")
    nmap <D-j> <A-j>
    nmap <D-k> <A-k>
    nmap <D-h> <A-h>
    nmap <D-l> <A-l>
    imap <D-j> <A-j>
    imap <D-k> <A-k>
    imap <D-h> <A-h>
    imap <D-l> <A-l>
    vmap <D-j> <A-j>
    vmap <D-k> <A-k>
    vmap <D-h> <A-h>
    vmap <D-l> <A-l>
endif
" }}}

"Copy, Cut, Paste {{{2
map <A-c> "+yy
map <A-x> "+dd
map <A-v> "+p
imap <A-c> <ESC>"+yy gi
imap <A-x> <ESC>"+dd gi
imap <A-v> <ESC>"+p gi
" }}}

" Folding {{{2
" Turn folding off for real, hopefully
" set nofoldenable
" set foldmethod=manual
" set foldmethod=syntax
" set foldmethod=marker
" set foldmarker=/*,*/
" set foldmethod=indent
" set foldlevelstart=0
nmap zb zMzv
nmap zg zMzO
nmap z<space> zA
" Mappings to easily toggle fold levels
nmap <silent> z0 :set foldlevel=0<cr>
nmap <silent> z1 :set foldlevel=1<cr>
nmap <silent> z2 :set foldlevel=2<cr>
nmap <silent> z3 :set foldlevel=3<cr>
nmap <silent> z4 :set foldlevel=4<cr>
nmap <silent> z5 :set foldlevel=5<cr>
nmap <silent> z6 :set foldlevel=6<cr>
nmap <silent> z7 :set foldlevel=7<cr>
nmap <silent> z8 :set foldlevel=8<cr>
nmap <silent> z9 :set foldlevel=9<cr>
"}}}

" Map <c-s> to write current buffer.
nmap <c-s> :w<cr>
imap <c-s> <c-o><c-s>
cmap: WQ wq
cmap: Wq wq
cmap: W w
cmap: Q q

" Undo in insert mode.
imap <c-z> <c-o>u
nmap <c-z> u

" Buffer naviation
nnoremap <leader>bp :bprevious<CR>
nnoremap <leader>bn :bnext<CR>
" nnoremap <C-b> :bprevious<CR>
" nnoremap <C-f> :bnext<CR>
nnoremap  <silent>   <tab>  :if &modifiable && !&readonly && &modified <CR> :write<CR> :endif<CR>:bnext<CR>
nnoremap  <silent> <s-tab>  :if &modifiable && !&readonly && &modified <CR> :write<CR> :endif<CR>:bprevious<CR>
" Close all the buffers
" nnoremap <leader>bo :BufOnly<cr>
nnoremap <leader>bo :Only<cr>
" clode this buffer
nnoremap <leader>bd :bdelete<cr>
" create a buffer menu
nnoremap <leader>bm :b <C-Z>
" create a buffer list
nnoremap <leader>bl :buffers<CR>:buffer<Space>
nnoremap <leader>bb :Buffers<CR>

" open Explorer
nnoremap <leader>e :edit .<cr>
nnoremap <leader>E :Explore<cr>
nnoremap <C-\> :Sexplore<cr>

" Useful mappings for managing tabs
map tn :tabnew<cr>
map to :tabonly<cr>
map tc :tabclose<cr>
map tm :tabmove
map tl :tabnext<cr>
map th :tabprevious<cr>
" Opens a new tab with the current buffer's path
map te :tabedit <c-r>=expand("%:p:h")<cr>/
" Opens a new tab with the current buffer
map tt :tabedit %<cr>
" edit .vimrc
nmap tv :tabedit ~/.vimrc<CR>
nmap ts :tabedit ~/.vimrc-standalone<CR>

" have <esc> remove search highlighting
" nnoremap <silent> <esc> :noh<return><esc>
" needed so that vim still understands escape sequences
" nnoremap <esc>^[ <esc>^[

"   Map escape key to jj -- much faster
imap jk <esc>

"   Join line above after current line.
nmap K :move-2<bar>:join<cr>
" nmap -K :move+<bar>:normal -J<cr>

"   SpellCheck with the first entry
nmap ss 1z=
nmap sp :set spell spelllang=pt_pt<CR>
nmap se :set spell spelllang=en_us<CR>
nmap sn :set nospell<CR>

" Use Alt-Mouse to select blockwise
noremap <M-LeftMouse> <LeftMouse><Esc><C-V>
noremap <M-LeftDrag> <LeftDrag>

" To search for visually selected text:
vmap // y/<C-R>"<CR>

" Shortcut to rapidly toggle `set list`
nmap <leader>sl :set list!<CR>
" Change path to current file directory
nnoremap <leader>cd :lcd %:p:h<CR>

nnoremap <Leader>w :call ToggleWrap()<CR>

" grep word under cursor
nnoremap <leader>gg :grep! "<C-R><C-W>"<CR>:cw<CR>
nnoremap <leader>gG :Ggrep "<C-R><C-W>"<CR>:cw<CR>
nnoremap <leader>gv :vimgrep! /<C-R><C-W>/j ./**<CR>:cw<CR>

" For local replace
nnoremap gr gd[{V%::s/<C-R>///gc<left><left><left>

" For global replace
nnoremap gR gD:%s/<C-R>///gc<left><left><left>

" 'p' to paste, 'gv' to re-select what was originally selected. 'y' to copy it again.
xnoremap p pgvy
" delete in insert mode
inoremap <c-l> <Del>

" The following lets you type Ngb to jump to buffer number N (from 1 to 99)
let c = 1
while c <= 99
    execute "nnoremap " . c . "gb :" . c . "b\<CR>"
    let c += 1
endwhile

" Keep window beffur delete
nnoremap <c-w>! <Plug>Kwbd

if has("nvim")
    tnoremap <Esc> <C-\><C-n>
endif

" Run line in shell and paste back the output
noremap Q !!$SHELL<CR>
" Breack line in normal mode Ctrl-j
:nnoremap <NL> i<CR><esc>

" Improve" the menu behavior
" inoremap <expr> <Esc>      pumvisible() ? "\<C-e>" : "\<Esc>" "comflicts with ycm
inoremap <expr> <CR>       pumvisible() ? "\<C-y>" : "\<CR>"
inoremap <expr> <Up>       pumvisible() ? "\<C-p>" : "\<Up>"
inoremap <expr> <Down>     pumvisible() ? "\<C-n>" : "\<Down>"

map <F3> :ToggleNumber<CR>
nnoremap <F4> :e %:p:s,.hpp$,.X123X,:s,.cpp$,.hpp,:s,.X123X$,.cpp,<CR>
" recreate tags file with F6
map <F6> :MakeTags<CR>
map <F7> :PreviewMarkDown<CR>

" Call MAKE
map <F8> :w <CR> <bar> :call Clevermake() <CR> <bar> :!./%< <CR>

" Toggle Type Completion
nnoremap <F9>           :ToggleTypeComplete<CR>
nnoremap <F10>          :ToggleShowTrailingSpaces<CR>
nnoremap <F12>          :StripTrailingWhitespace<CR>

"ECLIM
" nnoremap <C-LeftMouse> :CSearchContext<CR>
" nnoremap <C-RightMouse> :bdeleteq<CR>


" COMMANDS {{{1
command! -range=% FormatHtml <line1>,<line2>:!tidy -q -i --show-errors 0
command! -range=% FormatXml <line1>,<line2>:!tidy -q -i --show-errors 0 -xml
command! -range=% FormatPython <line1>,<line2>call YAPF()

command! -range=% FormatCpp  <line1>,<line2>:pyf /usr/share/clang/clang-format-3.8/clang-format.py
command! -nargs=0 PreviewMarkDown call Markdown_Preview()

" command! MakeTags !ctags -R .
command! MakeTags !ctags -R --sort=yes --c++-kinds=+p --fields=+iaS --extra=+q --exclude='.git' --exclude='log' .

"   Set a better wrapping comand
command! -nargs=0 WrapDefault set formatoptions=tcqj textwidth=80
command! -nargs=0 WrapAutoHard set formatoptions=tcqjanwr textwidth=80
command! -nargs=0 WrapHard set formatoptions=tcqjwr textwidth=80
command! -nargs=0 WrapUndoHard set formatoptions=tcqjwr textwidth=5000
command! -nargs=0 WrapSoftAt80 autocmd VimResized * let &columns=80

" Insert the current time
command! InsertTime :normal a<c-r>=strftime('%F %H:%M:%S.0 %z') <cr>

" Start a search for conditional branches, both implicit and explicit
command! FindConditionals :normal
            \ /\<if\>\|\<unless\>\|\<and\>\|\<or\>\|||\|&&<cr>

" Set tabstop, softtabstop and shiftwidth to the same value
command! -nargs=* SetTab call SetTab()

" Calls function ToggleNumber();
command! -nargs=0 ToggleNumber call ToggleNumber()

command! -nargs=0 StripTrailingWhitespace call StripTrailingWhitespace()

"delete the current file
command! DeleteFile call DeleteFile()
command! Rm call DeleteFile()
"delete the file and quit the buffer (quits vim if this was the last file)
command! RM call DeleteFile() <Bar> q!


command! -nargs=* Only call CloseHiddenBuffers()

"Bind the BufSel() function to a user-command
command! -nargs=1 Bs :call BufSel("<args>")

" Populat the quickfix with buffer list!
command! Qbuffers call setqflist(map(filter(range(1, bufnr('$')), 'buflisted(v:val)'), '{"bufnr":v:val}'))

function! Replace(bang, replace) "{{{2
" FUNCTIONS {{{1
    " Search for current word and replace with given text for files in arglist.
    let flag = 'ge'
    if !a:bang
        let flag .= 'c'
    endif
    let search = '\<' . escape(expand('<cword>'), '/\.*$^~[') . '\>'
    let replace = escape(a:replace, '/\&~')
    " execute 'argdo %s/' . search . '/' . replace . '/' . flag
    execute 'bufdo %s/' . search . '/' . replace . '/' . flag
endfunction
command! -nargs=1 -bang Replace :call Replace(<bang>0, <q-args>)
nnoremap <Leader>r :call Replace(1, input('Replace '.expand('<cword>').' with: '))<CR>

function! StripTrailingWhitespace() "{{{2
    if !&binary && &filetype != 'diff'
        " Preparation: save last search, and cursor position.
        let _s=@/
        let l = line(".")
        let c = col(".")
        " Do the business:
        %s/\s\+$//e
        " Clean up: restore previous search history, and cursor position
        let @/=_s
        call cursor(l, c)
    endif
endfunction

function! ToggleWrap() "{{{2
    if &linebreak
        echo "Wrap ON WithOut LineBrak"
        setlocal wrap nolinebreak
        set virtualedit=
        setlocal display+=lastline
        "noremap  <buffer> <silent> k gk
        "noremap  <buffer> <silent> j gj
        "noremap  <buffer> <silent> 0 g0
        "noremap  <buffer> <silent> $ g$
        noremap  <buffer> <silent> <Up>   gk
        noremap  <buffer> <silent> <Down> gj
        noremap  <buffer> <silent> <Home> g<Home>
        noremap  <buffer> <silent> <End>  g<End>
        inoremap <buffer> <silent> <Up>   <C-o>gk
        inoremap <buffer> <silent> <Down> <C-o>gj
        inoremap <buffer> <silent> <Home> <C-o>g<Home>
        inoremap <buffer> <silent> <End>  <C-o>g<End>
    elseif &wrap
        echo "Wrap OFF"
        setlocal nowrap
        set virtualedit=all
        silent! nunmap <buffer> <Up>
        silent! nunmap <buffer> <Home>
        silent! nunmap <buffer> <Down>
        silent! nunmap <buffer> <End>
        silent! iunmap <buffer> <Up>
        silent! iunmap <buffer> <Down>
        silent! iunmap <buffer> <Home>
        silent! iunmap <buffer> <End>
    else
        echo "Wrap ON With LineBreak"
        setlocal wrap linebreak
        set virtualedit=
        setlocal display+=lastline
        "noremap  <buffer> <silent> k gk
        "noremap  <buffer> <silent> j gj
        "noremap  <buffer> <silent> 0 g0
        "noremap  <buffer> <silent> $ g$
        noremap  <buffer> <silent> <Up>   gk
        noremap  <buffer> <silent> <Down> gj
        noremap  <buffer> <silent> <Home> g<Home>
        noremap  <buffer> <silent> <End>  g<End>
        inoremap <buffer> <silent> <Up>   <C-o>gk
        inoremap <buffer> <silent> <Down> <C-o>gj
        inoremap <buffer> <silent> <Home> <C-o>g<Home>
        inoremap <buffer> <silent> <End>  <C-o>g<End>
    endif
endfunction

function! ToggleNumber() "{{{2
    let currentnumberwidth=strlen(line('$'))
    if &relativenumber
        echo "Number ON"
        setlocal nonumber norelativenumber
        setlocal number
        setlocal showbreak=
        " let &columns=&columns-&numberwidth+currentnumberwidth
    elseif &number
        echo "Number OFF"
        setlocal nonumber norelativenumber
        setlocal showbreak=+++
        " let &columns=&columns-currentnumberwidth-1
    else
        echo "Number ON Relative (hybrid)"
        setlocal number relativenumber
        setlocal showbreak=
        setlocal numberwidth=2
        " let &columns=&columns+&numberwidth+1
    endif
endfunction

function! Clevermake() "{{{2
    if !exists("g:make_command")
        echo "Compiling using makeprg ..."
        :make
    else
        exec g:make_command
    endif
endfunction

function! SetTab() "{{{2
    let l:tabstop = 1 * input('set tabstop = softtabstop = shiftwidth = ')
    if l:tabstop > 0
        let &l:sts = l:tabstop
        let &l:ts = l:tabstop
        let &l:sw = l:tabstop
    endif
    call SummarizeTabs()
endfunction
function! SummarizeTabs()
    try
        echohl ModeMsg
        echon 'tabstop='.&l:ts
        echon ' shiftwidth='.&l:sw
        echon ' softtabstop='.&l:sts
        if &l:et
            echon ' expandtab'
        else
            echon ' noexpandtab'
        endif
    finally
        echohl None
    endtry
endfunction

function! BufSel(pattern) "{{{2
    let bufcount = bufnr("$")
    let currbufnr = 1
    let nummatches = 0
    let firstmatchingbufnr = 0
    while currbufnr <= bufcount
        if(bufexists(currbufnr))
            let currbufname = bufname(currbufnr)
            if(match(currbufname, a:pattern) > -1)
                echo currbufnr . ": ". bufname(currbufnr)
                let nummatches += 1
                let firstmatchingbufnr = currbufnr
            endif
        endif
        let currbufnr = currbufnr + 1
    endwhile
    if(nummatches == 1)
        execute ":buffer ". firstmatchingbufnr
    elseif(nummatches > 1)
        let desiredbufnr = input("Enter buffer number: ")
        if(strlen(desiredbufnr) != 0)
            execute ":buffer ". desiredbufnr
        endif
    else
        echo "No matching buffers"
    endif
endfunction

function! CloseHiddenBuffers() " {{{2
    " figure out which buffers are visible in any tab
    let visible = {}
    for t in range(1, tabpagenr('$'))
        for b in tabpagebuflist(t)
            let visible[b] = 1
        endfor
    endfor
    " close any buffer that are loaded and not visible
    let l:tally = 0
    for b in range(1, bufnr('$'))
        if bufloaded(b) && !has_key(visible, b)
            let l:tally += 1
            exe 'bw ' . b
        endif
    endfor
    echon "Deleted " . l:tally . " buffers"
endfun


function! DeleteFile(...) "{{{2
    if(exists('a:1'))
        let theFile=a:1
    elseif ( &ft == 'help' )
        echohl Error
        echo "Cannot delete a help buffer!"
        echohl None
        return -1
    else
        let theFile=expand('%:p')
    endif
    let delStatus=delete(theFile)
    if(delStatus == 0)
        echo "Deleted " . theFile
    else
        echohl WarningMsg
        echo "Failed to delete " . theFile
        echohl None
    endif
    return delStatus
endfunction

function! YAPF() range "{{{2
    " Determine range to format.
    let l:line_ranges = a:firstline . '-' . a:lastline
    let l:cmd = 'yapf --lines=' . l:line_ranges

    " Call YAPF with the current buffer
    if exists('*systemlist')
        let l:formatted_text = systemlist(l:cmd, join(getline(1, '$'), "\n") . "\n")
    else
        let l:formatted_text =
                    \ split(system(l:cmd, join(getline(1, '$'), "\n") . "\n"), "\n")
    endif

    if v:shell_error
        echohl ErrorMsg
        echomsg printf('"%s" returned error: %s', l:cmd, l:formatted_text[-1])
        echohl None
        return
    endif

    " Update the buffer.
    execute '1,' . string(line('$')) . 'delete'
    call setline(1, l:formatted_text)

    " Reset cursor to first line of the formatted range.
    call cursor(a:firstline, 1)
endfunction

function! Markdown_Preview() "{{{2
    let b:curr_file = expand('%:p')

    if executable('grip')
        call system('grip "' . b:curr_file . '" --export /tmp/vim-markdown-preview.html --title vim-markdown-preview.html')
    elseif executable('markdown_py')
        call system('markdown_py "' . b:curr_file . '" > /tmp/vim-markdown-preview.html')
    elseif executable('pandoc')
        call system('pandoc --standalone "' . b:curr_file . '" > /tmp/vim-markdown-preview.html')
    else
        call system('markdown "' . b:curr_file . '" > /tmp/vim-markdown-preview.html')
    endif
    if v:shell_error
        echo 'Install grip or pandoc.'
    endif

    let browser_win = system("xdotool search --name 'vim-markdown-preview.html'")
    if !browser_win
        if executable('surf')
            call system('surf /tmp/vim-markdown-preview.html 1>/dev/null 2>/dev/null &')
        else
            call system('xdg-open /tmp/vim-markdown-preview.html 1>/dev/null 2>/dev/null &')
        endif
    else
        let curr_wid = system('xdotool getwindowfocus')
        call system('xdotool windowmap ' . browser_win)
        call system('xdotool windowactivate ' . browser_win)
        call system("xdotool key 'ctrl+r'")
        call system('xdotool windowactivate ' . curr_wid)
    endif
endfunction

"SIMPLE PLUGINS{{{1
function! s:CommentaryPlugin() "{{{2
    function! s:surroundings() abort
        return split(get(b:, 'commentary_format', substitute(substitute(
                    \ &commentstring, '\S\zs%s',' %s','') ,'%s\ze\S', '%s ', '')), '%s', 1)
    endfunction

    function! s:strip_white_space(l,r,line) abort
        let [l, r] = [a:l, a:r]
        if stridx(a:line,l) == -1 && stridx(a:line,l[0:-2]) == 0 && a:line[strlen(a:line)-strlen(r[1:]):-1] == r[1:]
            return [l[0:-2], r[1:]]
        endif
        return [l, r]
    endfunction

    function! s:go(type,...) abort
        if a:0
            let [lnum1, lnum2] = [a:type, a:1]
        else
            let [lnum1, lnum2] = [line("'["), line("']")]
        endif

        let [l_, r_] = s:surroundings()
        let uncomment = 2
        for lnum in range(lnum1,lnum2)
            let line = matchstr(getline(lnum),'\S.*\s\@<!')
            let [l, r] = s:strip_white_space(l_,r_,line)
            if line != '' && (stridx(line,l) || line[strlen(line)-strlen(r) : -1] != r)
                let uncomment = 0
            endif
        endfor

        for lnum in range(lnum1,lnum2)
            let line = getline(lnum)
            if strlen(r) > 2 && l.r !~# '\\'
                let line = substitute(line,
                            \'\M'.r[0:-2].'\zs\d\*\ze'.r[-1:-1].'\|'.l[0].'\zs\d\*\ze'.l[1:-1],
                            \'\=substitute(submatch(0)+1-uncomment,"^0$\\|^-\\d*$","","")','g')
            endif
            if uncomment
                let line = substitute(line,'\S.*\s\@<!','\=submatch(0)[strlen(l):-strlen(r)-1]','')
            else
                let line = substitute(line,'^\%('.matchstr(getline(lnum1),'^\s*').'\|\s*\)\zs.*\S\@<=','\=l.submatch(0).r','')
            endif
            call setline(lnum,line)
        endfor
        let modelines = &modelines
        try
            set modelines=0
            silent doautocmd User CommentaryPost
        finally
            let &modelines = modelines
        endtry
    endfunction

    function! s:textobject(inner) abort
        let [l_, r_] = s:surroundings()
        let [l, r] = [l_, r_]
        let lnums = [line('.')+1, line('.')-2]
        for [index, dir, bound, line] in [[0, -1, 1, ''], [1, 1, line('$'), '']]
            while lnums[index] != bound && line ==# '' || !(stridx(line,l) || line[strlen(line)-strlen(r) : -1] != r)
                let lnums[index] += dir
                let line = matchstr(getline(lnums[index]+dir),'\S.*\s\@<!')
                let [l, r] = s:strip_white_space(l_,r_,line)
            endwhile
        endfor
        while (a:inner || lnums[1] != line('$')) && empty(getline(lnums[0]))
            let lnums[0] += 1
        endwhile
        while a:inner && empty(getline(lnums[1]))
            let lnums[1] -= 1
        endwhile
        if lnums[0] <= lnums[1]
            execute 'normal! 'lnums[0].'GV'.lnums[1].'G'
        endif
    endfunction

    xnoremap <silent> <Plug>Commentary     :<C-U>call <SID>go(line("'<"),line("'>"))<CR>
    nnoremap <silent> <Plug>Commentary     :<C-U>set opfunc=<SID>go<CR>g@
    nnoremap <silent> <Plug>CommentaryLine :<C-U>set opfunc=<SID>go<Bar>exe 'norm! 'v:count1.'g@_'<CR>
    onoremap <silent> <Plug>Commentary        :<C-U>call <SID>textobject(0)<CR>
    nnoremap <silent> <Plug>ChangeCommentary c:<C-U>call <SID>textobject(1)<CR>
    nmap <silent> <Plug>CommentaryUndo <Plug>Commentary<Plug>Commentary
    command! -range -bar Commentary call s:go(<line1>,<line2>)

    if !hasmapto('<Plug>Commentary') || maparg('gc','n') ==# ''
        xmap gc  <Plug>Commentary
        nmap gc  <Plug>Commentary
        omap gc  <Plug>Commentary
        nmap gcc <Plug>CommentaryLine
        nmap gcu <Plug>Commentary<Plug>Commentary
        if maparg('c','n') ==# ''
            nmap cgc <Plug>ChangeCommentary
        endif
    endif
endfunction

autocmd FileType c,cpp,java setlocal commentstring=//\ %s
call s:CommentaryPlugin()

function! s:TabCompletePlugin() "{{{2
    let g:vcm_s_tab_behavior = 0
    let g:vcm_direction = 'n'
    let g:vcm_omni_pattern = '\k\+\(\.\|->\|::\)\k*$'
    " let g:vcm_s_tab_mapping = ''

    function! s:vim_completes_me(shift_tab)
        let dirs = ["\<c-p>", "\<c-n>"]
        let dir = g:vcm_direction =~? '[nf]'
        let dir_cmd = a:shift_tab ? dirs[!dir] : dirs[dir]
        let vcm_map = exists('b:vcm_tab_complete') ? b:vcm_tab_complete : ''

        if pumvisible()
            " return a:shift_tab ? dirs[!dir] : dirs[dir]
            return dir_cmd
        endif

        " Figure out whether we should indent/de-indent.
        let pos = getpos('.')
        let substr = matchstr(strpart(getline(pos[1]), 0, pos[2]-1), "[^ \t]*$")
        if empty(substr)
            let s_tab_deindent = pos[2] > 1 ? "\<C-h>" : ""
            return (a:shift_tab && !g:vcm_s_tab_behavior) ? l:s_tab_deindent : "\<Tab>"
        endif

        if a:shift_tab && exists('g:vcm_s_tab_mapping')
            return g:vcm_s_tab_mapping
        endif

        let omni_pattern = get(b:, 'vcm_omni_pattern', get(g:, 'vcm_omni_pattern'))
        let is_omni_pattern = match(substr, omni_pattern) != -1
        let file_pattern = (has('win32') || has('win64')) ? '\\\|\/' : '\/'
        let is_file_pattern = match(substr, file_pattern) != -1

        if is_omni_pattern && (!empty(&omnifunc))
            " Check position so that we can fallback if at the same pos.
            if get(b:, 'tab_complete_pos', []) == pos && b:completion_tried
                " let exp = "\<C-x>" . dirs[!dir]
                let exp = "\<C-x>" . dir_cmd
            else
                echo "Looking for members..."
                let exp = (!empty(&completefunc) && vcm_map ==? "user") ? "\<C-x>\<C-u>" : "\<C-x>\<C-o>"
                let b:completion_tried = 1
            endif
            let b:tab_complete_pos = pos
            return exp
        elseif is_file_pattern
            return "\<C-x>\<C-f>"
        endif

        " First fallback to keyword completion if special completion was already tried.
        if exists('b:completion_tried') && b:completion_tried
            let b:completion_tried = 0
            " return "\<C-e>" . dirs[!dir]
            return "\<C-e>" . dir_cmd
        endif

        " Fallback
        let b:completion_tried = 1
        if vcm_map ==? "user"
            return "\<C-x>\<C-u>"
        elseif vcm_map ==? "omni"
            echo "Looking for members..."
            return "\<C-x>\<C-o>"
        elseif vcm_map ==? "vim"
            return "\<C-x>\<C-v>"
        else
            " return dirs[!dir]
            return dir_cmd
        endif
    endfunction

    inoremap <expr> <plug>vim_completes_me_forward  <sid>vim_completes_me(0)
    inoremap <expr> <plug>vim_completes_me_backward <sid>vim_completes_me(1)

    " Maps: {{{3
    imap <Tab>   <plug>vim_completes_me_forward
    imap <S-Tab> <plug>vim_completes_me_backward

    augroup VCM "{{{3
        autocmd!
        autocmd InsertEnter * let b:completion_tried = 0
        if v:version > 703 || v:version == 703 && has('patch598')
            autocmd CompleteDone * let b:completion_tried = 0
        endif
        autocmd FileType text,markdown let b:vcm_tab_complete = 'dict'
        autocmd FileType c,cpp let b:vcm_tab_complete = 'user'
    augroup END
endfunction

call s:TabCompletePlugin()

function! s:TypeCompletePlugin() "{{{2

    set completeopt+=menu
    set completeopt+=menuone
    set completeopt+=noinsert

    function! s:TypeComplete(char)
        if !pumvisible() &&
                    \ !exists('s:completed') &&
                    \ getline('.')[col('.')-3:col('.')-2].a:char =~# '\k\k\k'
            let s:completed = 1
            noautocmd call feedkeys("\<C-n>\<C-p>", "nt")
        endif
    endfunction

    function! s:ToggleTypeComplete()
        if !exists('#TypeCompleteAutoGroup#InsertCharPre')
            augroup TypeCompleteAutoGroup
                autocmd!
                autocmd InsertCharPre * call <SID>TypeComplete(v:char)
                autocmd CompleteDone * if exists('s:completed') | unlet s:completed | endif
            augroup END
            echo "TypeComplete ON"
        else
            augroup TypeCompleteAutoGroup
                autocmd!
            augroup END
            echo "TypeComplete OFF"
        endif
    endfunction

    command! -nargs=0 ToggleTypeComplete call s:ToggleTypeComplete()

endfunction

call s:TypeCompletePlugin()

function! s:ShowTrailingSpacesPlugin() "{{{2

    highlight HighlightExtraWhitespace ctermbg=red guibg=red

    function! s:SetWhitespaceMatch(mode)
        let pattern = (a:mode == 'i') ? '\s\+\%#\@<!$' : '\s\+$'
        if exists('w:whitespace_match_number')
            call matchdelete(w:whitespace_match_number)
            call matchadd('ExtraWhitespace', pattern, 10, w:whitespace_match_number)
        else
            " Something went wrong, try to be graceful.
            let w:whitespace_match_number =  matchadd('ExtraWhitespace', pattern)
        endif
    endfunction

    function! s:ToggleShowTrailingSpaces()
        if exists('#WhitespaceMatch#InsertEnter')
            augroup WhitespaceMatch
                autocmd!
            augroup end
            highlight link ExtraWhitespace none
            echo "Hide trailing whitespaces"
        else
            augroup WhitespaceMatch
                " Remove ALL autocommands for the WhitespaceMatch group.
                autocmd!
                autocmd BufWinEnter * let w:whitespace_match_number =
                            \ matchadd('ExtraWhitespace', '\s\+$')
                autocmd InsertEnter * call s:SetWhitespaceMatch('i')
                autocmd InsertLeave * call s:SetWhitespaceMatch('n')
            augroup END
            highlight link ExtraWhitespace HighlightExtraWhitespace
            echo "Show trailing whitespaces"
        endif
    endfunction

    command! -nargs=0 ToggleShowTrailingSpaces call s:ToggleShowTrailingSpaces()

endfunction

call s:ShowTrailingSpacesPlugin()

function! s:BaseSyntaxPlugin() "{{{2

    " hi link baseOperator Operator
    " hi link baseDelimiter Delimiter
    " hi link nonAscii Special

    " let w:m1_bs=matchadd('baseOperator', '\(\ +\ \|=\|\ -\ \|\^\|\ \*\ \|-=\|+=\|\*=\|/=\|\ /\ \|\ <\ \|\ >\ \|>=\|<=\|||\|&&\)',-1)
    " let w:m2_bs=matchadd('basedelimiter', '[(){},]', -1)
    " let w:m3_bs=matchadd('nonAscii', '[^\x00-\x7f]', -1)

    let s:BSenabled = 0

    function! s:ToggleHiBaseSyntax()
        if s:BSenabled == 1
            hi link baseOperator none
            " hi link baseDelimiter none
            hi link nonAscii none
            call matchdelete(w:m1_bs)
            " call matchdelete(w:m2_bs)
            call matchdelete(w:m3_bs)
            let s:BSenabled = 0
            echo "HighlightBaseSyntax OFF"
        else
            hi link baseOperator Operator
            " hi link baseDelimiter Delimiter
            hi link nonAscii Special
            let w:m1_bs=matchadd('baseOperator', '\(\ +\ \|=\|\ -\ \|\^\|\ \*\ \|-=\|+=\|\*=\|/=\|\ /\ \|\ <\ \|\ >\ \|>=\|<=\|||\|&&\)',-1)
            " let w:m2_bs=matchadd('basedelimiter', '[(){},]', -1)
            let w:m3_bs=matchadd('nonAscii', '[^\x00-\x7f]', -1)
            let s:BSenabled = 1
            echo "HighlightBaseSyntax ON"
        endif
    endfunction

    command! -nargs=0 ToggleHiBaseSyntax call s:ToggleHiBaseSyntax()

endfunction
call s:BaseSyntaxPlugin()

function! s:MaximazerPlugin() "{{{2

    if !exists('g:maximizer_set_default_mapping')
        let g:maximizer_set_default_mapping = 1
    endif

    if !exists('g:maximizer_set_mapping_with_bang')
        let g:maximizer_set_mapping_with_bang = 0
    endif

    if !exists('g:maximizer_restore_on_winleave')
        let g:maximizer_restore_on_winleave = 0
    endif

    if !exists('g:maximizer_default_mapping_key')
        let g:maximizer_default_mapping_key = '<F5>'
    endif

    command! -bang -nargs=0 -range MaximizerToggle :call s:toggle(<bang>0)

    if g:maximizer_set_default_mapping
        let command = ':MaximizerToggle'

        if g:maximizer_set_mapping_with_bang
            let command .= '!'
        endif

        silent! exe 'nnoremap <silent>' . g:maximizer_default_mapping_key . ' ' . command . '<CR>'
        silent! exe 'vnoremap <silent>' . g:maximizer_default_mapping_key . ' ' . command . '<CR>gv'
        silent! exe 'inoremap <silent>' . g:maximizer_default_mapping_key . ' <C-o>' . command . '<CR>'
    endif

    fun! s:maximize()
        let t:maximizer_sizes = { 'before': winrestcmd() }
        vert resize | resize
        let t:maximizer_sizes.after = winrestcmd()
        normal! ze
    endfun

    fun! s:restore()
        if exists('t:maximizer_sizes')
            silent! exe t:maximizer_sizes.before
            if t:maximizer_sizes.before != winrestcmd()
                wincmd =
            endif
            unlet t:maximizer_sizes
            normal! ze
        end
    endfun

    fun! s:toggle(force)
        if exists('t:maximizer_sizes') && (a:force || (t:maximizer_sizes.after == winrestcmd()))
            call s:restore()
        elseif winnr('$') > 1
            call s:maximize()
        endif
    endfun

    if g:maximizer_restore_on_winleave
        augroup maximizer
            au!
            au WinLeave * call s:restore()
        augroup END
    endif

endfunction

call s:MaximazerPlugin()

" Tweaks for filebrowsing {{{2
" let g:netrw_banner=0            " disable annoying banner
" let g:netrw_liststyle=3         " tree view
" let g:netrw_browse_split=4      " use the previous window to open file
" let g:netrw_altv=1              " open splits to the right
" let g:netrw_winsize = 25        " sets the width to 25% of the page
" let g:netrw_winsize = -28 " absolute width of netrw window
let g:netrw_list_hide=netrw_gitignore#Hide()
let g:netrw_list_hide.=',\(^\|\s\s\)\zs\.\S\+'
let g:netrw_sort_sequence = '[\/]$,*' " sort is affecting only: directories on the top, files below

autocmd FileType netrw set nolist

