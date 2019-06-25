" This is Joel Silva's .vimrc file
" 2014-11-15 01:09:03.0 +0100

autocmd! bufwritepost .vimrc source %

source ~/.vimrc-standalone

let g:python_host_prog='/usr/bin/python'
" let g:python3_host_prog=
"VIM PLUG {{{1

call plug#begin('~/.vim/plugged')

Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-repeat'
" Plug 'tpope/vim-commentary'
Plug 'scrooloose/nerdtree', { 'on': 'NERDTreeToggle' }

Plug 'SirVer/ultisnips'
Plug 'honza/vim-snippets'

Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'

Plug 'jamessan/vim-gnupg'
Plug 'godlygeek/tabular'
Plug 'majutsushi/tagbar'
Plug 'vim-scripts/a.vim'
Plug 'vim-scripts/confluencewiki.vim'
" Plug 'ludovicchabant/vim-gutentags'

Plug 'vimwiki/vimwiki'

Plug 'lervag/vimtex', {'for': 'tex'}
Plug 'vim-scripts/DoxygenToolkit.vim'
Plug 'vim-scripts/drools.vim'

Plug 'Chiel92/vim-autoformat'
Plug 'martinda/Jenkinsfile-vim-syntax'

" Plug 'airblade/vim-gitgutter' , {'for' : 'cc,hpp,h,cpp,c'}
Plug 'python-mode/python-mode', {'for': 'python', 'branch': 'develop'}
" Plug 'ervandew/supertab' "included in ycm

" Sintax plugins
Plug 'octol/vim-cpp-enhanced-highlight' , {'for' : 'cc,hpp,h,cpp,c'}
Plug 'sirtaj/vim-openscad', {'for': 'scad'}
Plug 'Glench/Vim-Jinja2-Syntax'

Plug 'prabirshrestha/async.vim'
Plug 'prabirshrestha/vim-lsp'

" NEOVIM Only
" if has('nvim')
" Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
" Plug 'w0rp/ale'
" else
" Plug 'Valloric/YouCompleteMe' , { 'dir': '~/.vim/plugged/YouCompleteMe', 'do': 'python3 install.py --clang-completer' }
" endif

call plug#end()
"}}}

"PLUGIN SPECIFIC {{{1
" fugitive {{{2
if !empty(glob("~/.vim/plugged/vim-fugitive/plugin/fugitive.vim"))
    nnoremap <silent> <leader>gs :Gstatus<cr>
    nnoremap <silent> <leader>gd :Gdiff<cr>
    nnoremap <silent> <leader>gc :Gcommit<cr>
    nnoremap <silent> <leader>gb :Gblame<cr>
    nnoremap <silent> <leader>gl :Glog<cr>
    nnoremap <silent> <leader>gp :Git push<cr>
    nnoremap <silent> <leader>gr :Gread<cr>
    nnoremap <silent> <leader>gw :Gwrite<cr>
    nnoremap <silent> <leader>ge :Gedit<cr>
    nnoremap <silent> <leader>ga :Git add -p %<cr>
endif
"}}}
" ultisnipets {{{
if !empty(glob("~/.vim/plugged/ultisnips/plugin/UltiSnips.vim"))
    " trigger configuration. do not use <tab> if you
    " use https://github.com/valloric/youcompleteme.
    let g:UltiSnipsExpandTrigger="<c-j>"
    let g:UltiSnipsListSnippets="<c-b>"
    let g:UltiSnipsJumpForwardTrigger="<c-j>"
    let g:UltiSnipsJumpBackwardTrigger="<c-k>"
    " let g:UltiSnipsexpandTrigger="<nop>"
    " let g:UltiSnipsJumpForwardTrigger="<nop>"
    " let g:UltiSnipsJumpBackwardTrigger="<nop>"

    " if you want :UltiSnipsEdit to split your window.
    let g:UltiSnipsEditSplit="context"
    " snippets are separated from the engine. add this if you want them:
    let g:UltiSnipsSnippetsDir = "~/.vim/ultisnips"
    let g:UltiSnipsSnippetDirectories =
                \ [$home.'/.vim/plugged/vim-snippets/ultisnips/', $home.'/.vim/ultisnips/']
endif
"}}}
" nerdtree {{{2
if !empty(glob("~/.vim/plugged/nerdtree/plugin/NERD_tree.vim"))
    nnoremap <leader>nt :NERDTreeToggle<cr>
    nnoremap <C-\> :NERDTreeToggle<cr>
    nnoremap <leader>nm :NERDTreeMirror<cr>
    nnoremap <leader>nf :NERDTreeFind<cr>


    let g:nerdtreewinpos = "left"

    let nerdspacedelims=1
    let nerdcompactsexycoms=1
    let g:nerdcustomdelimiters = { 'racket': { 'left': ';', 'leftalt': '#|', 'rightalt': '|#' } }
endif
"}}}
" fzf {{{2
if !empty(glob("~/.vim/plugged/fzf.vim/plugin/fzf.vim"))
    nnoremap <leader>bb :Buffers<CR>
    " nnoremap <leader>t :Tags<CR>
    nnoremap <C-p> :Files<CR>
    nnoremap <leader>ag :Ag<CR>


    " Command for git grep
    " - fzf#vim#grep(command, with_column, [options], [fullscreen])
    command! -bang -nargs=* GGrep
                \ call fzf#vim#grep(
                \   'git grep --line-number '.shellescape(<q-args>), 0,
                \   { 'dir': systemlist('git rev-parse --show-toplevel')[0] }, <bang>0)

    " Override Colors command. You can safely do this in your .vimrc as fzf.vim
    " will not override existing commands.
    command! -bang Colors
                \ call fzf#vim#colors({'left': '15%', 'options': '--reverse --margin 30%,0'}, <bang>0)

    " Augmenting Ag command using fzf#vim#with_preview function
    "   * fzf#vim#with_preview([[options], [preview window], [toggle keys...]])
    "     * For syntax-highlighting, Ruby and any of the following tools are required:
    "       - Bat: https://github.com/sharkdp/bat
    "       - Highlight: http://www.andre-simon.de/doku/highlight/en/highlight.php
    "       - CodeRay: http://coderay.rubychan.de/
    "       - Rouge: https://github.com/jneen/rouge
    "
    "   :Ag  - Start fzf with hidden preview window that can be enabled with "?" key
    "   :Ag! - Start fzf in fullscreen and display the preview window above
    command! -bang -nargs=* Ag
                \ call fzf#vim#ag(<q-args>,
                \                 <bang>0 ? fzf#vim#with_preview('up:60%')
                \                         : fzf#vim#with_preview('right:50%:hidden', '?'),
                \                 <bang>0)

    " Similarly, we can apply it to fzf#vim#grep. To use ripgrep instead of ag:
    command! -bang -nargs=* Rg
                \ call fzf#vim#grep(
                \   'rg --column --line-number --no-heading --color=always --smart-case '.shellescape(<q-args>), 1,
                \   <bang>0 ? fzf#vim#with_preview('up:60%')
                \           : fzf#vim#with_preview('right:50%:hidden', '?'),
                \   <bang>0)

    " Likewise, Files command with preview window
    command! -bang -nargs=? -complete=dir Files
                \ call fzf#vim#files(<q-args>, fzf#vim#with_preview(), <bang>0)

endif
"}}}
" autoformat {{{2
if !empty(glob("~/.vim/plugged/vim-autoformat/plugin/autoformat.vim"))
    noremap <leader>= :Autoformat<cr>
    " let b:formatdef_custom_c='"astyle --mode=c --suffix=none --options=/home/user/special_project/astylerc"'
    " let b:formatdef_custom_c='"clang-format -style=~/.vim/clang_config/clang-format-ascat.yaml"'
    " let b:formatters_c = ['custom_c']
endif
"}}}
" vim-codefmt {{{2
if !empty(glob("~/.vim/plugged/vim-codefmt/bootstrap.vim"))
    augroup autoformat_settings
        " autocmd FileType bzl AutoFormatBuffer buildifier
        " autocmd FileType c,cpp,proto,javascript AutoFormatBuffer clang-format
        " autocmd FileType dart AutoFormatBuffer dartfmt
        " autocmd FileType go AutoFormatBuffer gofmt
        " autocmd FileType gn AutoFormatBuffer gn
        " autocmd FileType html,css,json AutoFormatBuffer js-beautify
        " autocmd FileType java AutoFormatBuffer google-java-format
        " Alternative: autocmd FileType python AutoFormatBuffer autopep8 autocmd FileType python AutoFormatBuffer yapf

        autocmd FileType bzl noremap <leader>= :FormatLines <cr>
        autocmd FileType c,cpp,proto,javascript noremap <leader>= :FormatLines <cr>
        autocmd FileType dart AutoFormatBuffer noremap <leader>= :FormatLines <cr>
        autocmd FileType go AutoFormatBuffer noremap <leader>= :FormatLines <cr>
        autocmd FileType gn AutoFormatBuffer noremap <leader>= :FormatLines <cr>
        autocmd FileType html,css,json noremap <leader>= :FormatLines <cr>
        autocmd FileType java noremap <leader>= :FormatLines <cr>
        autocmd FileType python noremap <leader>= :FormatLines <cr>
    augroup END
    " noremap <leader>= :FormatLines <cr>
endif
"}}}
" tagbar {{{2
if !empty(glob("~/.vim/plugged/tagbar/plugin/tagbar.vim"))
    nnoremap <leader>tt :TagbarToggle<cr>
endif
"}}}
" tabularize {{{2
if exists(":Tabularize")
    nmap <leader>a= :tabularize /=<cr>
    vmap <leader>a= :tabularize /=<cr>
    nmap <leader>a: :tabularize /:\zs<cr>
    vmap <leader>a: :tabularize /:\zs<cr>

    inoremap <silent> <bar>   <bar><esc>:call <sid>align()<cr>a

    function! s:align()
        let p = '^\s*|\s.*\s|\s*$'
        if exists(':tabularize') && getline('.') =~# '^\s*|' && (getline(line('.')-1) =~# p || getline(line('.')+1) =~# p)
            let column = strlen(substitute(getline('.')[0:col('.')],'[^|]','','g'))
            let position = strlen(matchstr(getline('.')[0:col('.')],'.*|\s*\zs.*'))
            tabularize/|/l1
            normal! 0
            call search(repeat('[^|]*|',column).'\s\{-\}'.repeat('.',position),'ce',line('.'))
        endif
    endfunction
endif
"}}}
" a.vim {{{2
if !empty(glob("~/.vim/plugged/a.vim"))
    map <A-tab> :A<cr>
endif
"}}}
" ale {{{2
if isdirectory(expand("~/.vim/plugged/ale/plugin/ale.vim"))
    " enable completion where available.
    let g:ale_completion_enabled = 1
endif
"}}}
" vim-cpp-enhanced-highlight {{{2
if !empty(glob("~/.vim/plugged/vim-cpp-enhanced-highlight/after/syntax/cpp.vim"))
    let g:cpp_class_scope_highlight = 1
    let g:cpp_member_variable_highlight = 1
    " let g:cpp_experimental_simple_template_highlight = 1
    let g:cpp_class_decl_highlight = 1
    " let g:cpp_experimental_template_highlight = 1
    let g:cpp_concepts_highlight = 1
    " let g:cpp_no_function_highlight = 1
endif
"}}}
" Supertab {{{2
if !empty(glob("~/.vim/plugged/supertab/plugin/supertab.vim"))
    let g:SuperTabDefaultCompletionType = "context"

    autocmd FileType cpp let g:SuperTabDefaultCompletionType = "<c-n>"
    let g:SuperTabContextDefaultCompletionType  = "<c-p>"
    let g:SuperTabNoCompleteBefore = []
    let g:SuperTabNoCompleteAfter = ['^', '\s']
endif
"}}}
" vim-commentary {{{2
if !empty(glob("~/.vim/plugged/vim-commentary/plugin/commentary.vim"))
    autocmd FileType c,cpp,java setlocal commentstring=//\ %s
endif
"}}}
" VimWiki {{{2
if !empty(glob("~/.vim/plugged/vimwiki/plugin/vimwiki.vim"))
    let g:vimwiki_list = [{'path': '~/.vimwiki/md/',
                \ 'syntax': 'markdown', 'ext': '.md'}]

    let g:vimwiki_ext2syntax = {'.md': 'markdown',
                \ '.mkd': 'markdown',
                \ '.wiki': 'media'}
endif
"}}}
" vimtex {{{2
if !empty(glob("~/.vim/plugged/vimtex/autoload/vimtex.vim"))
    nmap  <leader>li  <plug>(vimtex-info)
    nmap  <leader>lI  <plug>(vimtex-info-full)
    nmap  <leader>lt  <plug>(vimtex-toc-open)
    nmap  <leader>lT  <plug>(vimtex-toc-toggle)
    nmap  <leader>lq  <plug>(vimtex-log)
    nmap  <leader>lv  <plug>(vimtex-view)
    nmap  <leader>lr  <plug>(vimtex-reverse-search)
    nmap  <leader>ll  <plug>(vimtex-compile)
    nmap  <leader>lL  <plug>(vimtex-compile-selected)
    nmap  <leader>lk  <plug>(vimtex-stop)
    nmap  <leader>lK  <plug>(vimtex-stop-all)
    nmap  <leader>le  <plug>(vimtex-errors)
    nmap  <leader>lo  <plug>(vimtex-compile-output)
    nmap  <leader>lg  <plug>(vimtex-status)
    nmap  <leader>lG  <plug>(vimtex-status-all)
    nmap  <leader>lc  <plug>(vimtex-clean)
    nmap  <leader>lC  <plug>(vimtex-clean-full)
    nmap  <leader>lm  <plug>(vimtex-imaps-list)
    nmap  <leader>lx  <plug>(vimtex-reload)
    nmap  <leader>lX  <plug>(vimtex-reload-state)
    nmap  <leader>ls  <plug>(vimtex-toggle-main)
endif
"}}}
"Jedi {{{2
if !empty(glob("~/.vim/plugged/jedi-vim/ftplugin/python/jedi.vim"))
    let g:jedi#goto_command = "<leader>c"
    let g:jedi#goto_assignments_command = "<leader>pg"
    let g:jedi#goto_definitions_command = "<leader>pd"
    let g:jedi#documentation_command = "K"
    let g:jedi#usages_command = "<leader>pu"
    let g:jedi#completions_command = "<C-Space>"
    let g:jedi#rename_command = "<leader>pr"
    let g:jedi#force_py_version = "2.7"
endif
"}}}
" YCM {{{2
if !empty(glob("~/.vim/plugged/YouCompleteMe/plugin/youcompleteme.vim"))
    let g:ycm_global_ycm_extra_conf = "~/.vim/ycm_extra_conf.py"
    let g:ycm_filetype_blacklist = {
                \ 'tagbar' : 1,
                \ 'qf' : 1,
                \ 'notes' : 1,
                \ 'markdown' : 1,
                \ 'unite' : 1,
                \ 'text' : 1,
                \ 'vimwiki' : 1,
                \ 'pandoc' : 1,
                \ 'infolog' : 1,
                \ 'mail' : 1
                \}
    let g:ycm_auto_trigger = 1
    let g:ycm_min_num_of_chars_for_completion = 2
    let g:ycm_autoclose_preview_window_after_completion=1

    " nnoremap <C-LeftMouse> <LeftMouse>:YcmCompleter GoToDefinitionElseDeclaration<CR>
    " nnoremap <C-]> :YcmCompleter GoToDefinitionElseDeclaration<CR>

endif
"}}}
" DoxygenToolkit {{{2
if !empty(glob("~/.vim/plugged/DoxygenToolkit.vim"))
    " let g:DoxygenToolkit_commentType = "C++"
endif

"}}}
" vim-lsp {{{2
if !empty(glob("~/.vim/plugged/vim-lsp/plugin/lsp.vim"))
    if executable('clangd')
        augroup lsp_clangd
            autocmd!
            autocmd User lsp_setup call lsp#register_server({
                        \ 'name': 'clangd',
                        \ 'cmd': {server_info->['clangd', '-background-index']},
                        \ 'whitelist': ['c', 'cpp', 'objc', 'objcpp'],
                        \ })
            autocmd FileType c setlocal omnifunc=lsp#complete
            autocmd FileType cpp setlocal omnifunc=lsp#complete
            autocmd FileType objc setlocal omnifunc=lsp#complete
            autocmd FileType objcpp setlocal omnifunc=lsp#complete
        augroup end
    endif
    if executable('ccls')
        augroup lsp_ccls
            autocmd User lsp_setup call lsp#register_server({
                        \ 'name': 'ccls',
                        \ 'cmd': {server_info->['ccls']},
                        \ 'root_uri': {server_info->lsp#utils#path_to_uri(lsp#utils#find_nearest_parent_file_directory(lsp#utils#get_buffer_path(), 'compile_commands.json'))},
                        \ 'initialization_options': {},
                        \ 'whitelist': ['c', 'cpp', 'objc', 'objcpp', 'cc'],
                        \ })
            autocmd FileType c setlocal omnifunc=lsp#complete
            autocmd FileType cpp setlocal omnifunc=lsp#complete
            autocmd FileType objc setlocal omnifunc=lsp#complete
            autocmd FileType objcpp setlocal omnifunc=lsp#complete
            autocmd FileType cc setlocal omnifunc=lsp#complete
        augroup end
    endif
endif
"}}}

