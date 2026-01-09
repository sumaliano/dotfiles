" Joel Silva's Consolidated Vimrc
" Minimal, modern, and functional

"""" Basic Settings {{{1
set nocompatible
set number                " show line numbers
set relativenumber        " hybrid line numbers
set wrap                  " wrap lines
set encoding=utf-8        " UTF-8 encoding
set mouse=a               " enable mouse support
set history=1000          " command history
set laststatus=2          " always show statusline
set ruler                 " show cursor position
set showcmd               " show partial commands
set showmatch             " highlight matching brackets
set visualbell            " blink instead of beep
set wildmenu              " visual autocomplete for command menu
set wildmode=longest:full,full
set lazyredraw            " redraw only when needed
set hidden                " allow hidden buffers with unsaved changes
set autoread              " reload files changed outside vim
set scrolloff=3           " keep 3 lines visible above/below cursor
set sidescrolloff=5       " keep 5 columns visible
set updatetime=250        " faster updates

" Better splits
set splitbelow            " open new split below
set splitright            " open new vsplit to right

" Ignore common files
set wildignore+=*/node_modules/*,*/__pycache__/*,*.pyc,*/.git/*
set wildignore+=*.o,*.obj,*.swp,*.bak

"""" Key Bindings {{{1
let mapleader = " "

" Quick escape from insert mode
inoremap jk <esc>

" Move by visual line (don't skip wrapped lines)
nnoremap j gj
nnoremap k gk

" Clear search highlighting
nnoremap <CR> :nohlsearch<CR><CR>

" Search for visually selected text
vnoremap // y/<C-R>"<CR>

" Move lines up/down with Alt+j/k
nnoremap <A-j> :m .+1<CR>==
nnoremap <A-k> :m .-2<CR>==
vnoremap <A-j> :m '>+1<CR>gv=gv
vnoremap <A-k> :m '<-2<CR>gv=gv

" Buffer navigation
nnoremap <leader>bn :bnext<CR>
nnoremap <leader>bp :bprevious<CR>
nnoremap <leader>bd :bdelete<CR>
nnoremap <leader>bo :call CloseHiddenBuffers()<CR>
nnoremap <silent> <tab> :bnext<CR>
nnoremap <silent> <s-tab> :bprevious<CR>

" File explorer
nnoremap <leader>e :edit .<CR>
nnoremap - :edit %:h<CR>

" Tab navigation
nnoremap <leader>tn :tabnew<CR>
nnoremap <leader>tq :tabclose<CR>
nnoremap <leader>tl :tabnext<CR>
nnoremap <leader>th :tabprevious<CR>

" Quick line break in normal mode
nnoremap <NL> i<CR><esc>

" Change directory to current file
nnoremap <leader>cd :lcd %:p:h<CR>

" Strip trailing whitespace
nnoremap <leader>sw :call StripWhitespace()<CR>

"""" Appearance {{{1
set t_Co=256
set background=dark
set cursorline            " highlight current line

" Colorscheme with fallback
silent! colorscheme badwolf
if !exists('g:colors_name')
    silent! colorscheme srcery
    if !exists('g:colors_name')
        colorscheme desert
    endif
endif

" Syntax highlighting
syntax enable
filetype plugin indent on

" Status line colors
hi StatusLine ctermbg=39 ctermfg=16
hi StatusLineNC ctermbg=234 ctermfg=245
au InsertEnter * hi StatusLine ctermbg=178 ctermfg=16
au InsertLeave * hi StatusLine ctermbg=39 ctermfg=16

" Simple but informative status line
set statusline=%<\ %f\ %m%r%w
set statusline+=%=
set statusline+=\ %y\
set statusline+=%{&fenc!=''?&fenc:&enc}[%{&ff}]\
set statusline+=%3p%%\ %l:%c\

"""" Tab and Indent Settings {{{1
set tabstop=4             " display width of tab character
set shiftwidth=4          " indent width
set softtabstop=4         " spaces inserted by <Tab>
set expandtab             " use spaces instead of tabs
set smarttab              " smart tab behavior
set autoindent            " copy indent from current line
set smartindent           " smart auto-indenting

"""" Search Settings {{{1
set incsearch             " search as you type
set hlsearch              " highlight search matches
set ignorecase            " ignore case in search
set smartcase             " unless uppercase is used

"""" Modern Vim Features {{{1
" Persistent undo
if has('persistent_undo')
    set undofile
    set undodir=~/.vim/undo
    set undolevels=1000
    set undoreload=10000
    " Create undo directory if it doesn't exist
    if !isdirectory(expand('~/.vim/undo'))
        call mkdir(expand('~/.vim/undo'), 'p')
    endif
endif

" Better backup and swap handling
set backup
set backupdir=~/.vim/backup
set directory=~/.vim/swap
if !isdirectory(expand('~/.vim/backup'))
    call mkdir(expand('~/.vim/backup'), 'p')
endif
if !isdirectory(expand('~/.vim/swap'))
    call mkdir(expand('~/.vim/swap'), 'p')
endif

" Merge sign column with number column
if has('nvim-0.5') || has('patch-8.1.1564')
    set signcolumn=number
endif

" Better mouse support in terminals
if !has('nvim') && &term =~ '^screen'
    set ttymouse=sgr
endif

"""" File Type Settings {{{1
if has('autocmd')
    augroup filetypes
        autocmd!
        autocmd FileType python,javascript set sw=4 sts=4 ts=4 et
        autocmd FileType ruby,yaml,html,css,scss set sw=2 sts=2 ts=2 et
        autocmd FileType tex,markdown set wrap linebreak
        autocmd FileType c,cpp set colorcolumn=100
        autocmd FileType vim set foldmethod=marker
        autocmd FileType make set noexpandtab

        " Close quickfix with q
        autocmd FileType qf nnoremap <buffer> <silent> q :cclose<CR>
    augroup END

    " Auto-set makeprg for C/C++ if no Makefile
    augroup makeprg
        autocmd!
        autocmd FileType c if !filereadable("Makefile") && !filereadable("makefile")
            \ | set makeprg=gcc\ -o\ %<\ %
            \ | endif
        autocmd FileType cpp if !filereadable("Makefile") && !filereadable("makefile")
            \ | set makeprg=g++\ -std=c++11\ -o\ %<\ %
            \ | endif
    augroup END
endif

"""" Functions {{{1

" Strip trailing whitespace
function! StripWhitespace()
    if !&binary && &filetype != 'diff'
        let _s=@/
        let l = line(".")
        let c = col(".")
        %s/\s\+$//e
        let @/=_s
        call cursor(l, c)
    endif
endfunction

" Close all hidden buffers
function! CloseHiddenBuffers()
    let visible = {}
    for t in range(1, tabpagenr('$'))
        for b in tabpagebuflist(t)
            let visible[b] = 1
        endfor
    endfor
    let tally = 0
    for b in range(1, bufnr('$'))
        if bufloaded(b) && !has_key(visible, b)
            let tally += 1
            exe 'bw ' . b
        endif
    endfor
    echon "Closed " . tally . " hidden buffers"
endfunction

" Toggle number display modes
function! ToggleNumber()
    if &relativenumber
        setlocal nonumber norelativenumber
        echo "Line numbers: OFF"
    elseif &number
        setlocal number relativenumber
        echo "Line numbers: Hybrid"
    else
        setlocal number norelativenumber
        echo "Line numbers: Absolute"
    endif
endfunction

" Set consistent tab width
function! SetTab()
    let l:tabstop = 1 * input('set tabstop = softtabstop = shiftwidth = ')
    if l:tabstop > 0
        let &l:sts = l:tabstop
        let &l:ts = l:tabstop
        let &l:sw = l:tabstop
    endif
    call SummarizeTabs()
endfunction

function! SummarizeTabs()
    echohl ModeMsg
    echon 'tabstop='.&l:ts
    echon ' shiftwidth='.&l:sw
    echon ' softtabstop='.&l:sts
    echon &l:et ? ' expandtab' : ' noexpandtab'
    echohl None
endfunction

"""" Commands {{{1
command! -nargs=0 ToggleNumber call ToggleNumber()
command! -nargs=0 StripWhitespace call StripWhitespace()
command! -nargs=* SetTab call SetTab()
command! -nargs=0 CloseHidden call CloseHiddenBuffers()
command! -nargs=0 CloseHiddenBuffers call CloseHiddenBuffers()

"""" Simple Commentary Plugin {{{1
" Lightweight commenting plugin
function! s:surroundings() abort
    return split(get(b:, 'commentary_format', substitute(substitute(substitute(
                \ &commentstring, '^$', '%s', ''), '\S\zs%s',' %s', '') ,'%s\ze\S', '%s ', '')), '%s', 1)
endfunction

function! s:strip_white_space(l,r,line) abort
    let [l, r] = [a:l, a:r]
    if l[-1:] ==# ' ' && stridx(a:line,l) == -1 && stridx(a:line,l[0:-2]) == 0
        let l = l[:-2]
    endif
    if r[0] ==# ' ' && a:line[-strlen(r):] != r && a:line[1-strlen(r):] == r[1:]
        let r = r[1:]
    endif
    return [l, r]
endfunction

function! s:go(...) abort
    if !a:0
        let &operatorfunc = matchstr(expand('<sfile>'), '[^. ]*$')
        return 'g@'
    elseif a:0 > 1
        let [lnum1, lnum2] = [a:1, a:2]
    else
        let [lnum1, lnum2] = [line("'["), line("']")]
    endif

    let [l, r] = s:surroundings()
    let uncomment = 2
    for lnum in range(lnum1,lnum2)
        let line = matchstr(getline(lnum),'\S.*\s\@<!')
        let [l, r] = s:strip_white_space(l,r,line)
        if len(line) && (stridx(line,l) || line[strlen(line)-strlen(r) : -1] != r)
            let uncomment = 0
        endif
    endfor

    for lnum in range(lnum1,lnum2)
        let line = getline(lnum)
        if uncomment
            let line = substitute(line,'\S.*\s\@<!','\=submatch(0)[strlen(l):-strlen(r)-1]','')
        else
            let line = substitute(line,'^\s*\zs.*\S\@<=','\=l.submatch(0).r','')
        endif
        call setline(lnum,line)
    endfor
    return ''
endfunction

command! -range -bar Commentary call s:go(<line1>,<line2>)
xnoremap <expr> <Plug>Commentary <SID>go()
nnoremap <expr> <Plug>Commentary <SID>go()
nnoremap <expr> <Plug>CommentaryLine <SID>go() . '_'

if !hasmapto('<Plug>Commentary') || maparg('gc','n') ==# ''
    xmap gc <Plug>Commentary
    nmap gc <Plug>Commentary
    nmap gcc <Plug>CommentaryLine
endif

augroup Commentary
    autocmd!
    autocmd FileType c,cpp,java setlocal commentstring=//\ %s
    autocmd FileType python,bash,sh setlocal commentstring=#\ %s
    autocmd FileType vim setlocal commentstring=\"\ %s
augroup END

" 1}}}

" vim: foldmethod=marker foldlevel=0
