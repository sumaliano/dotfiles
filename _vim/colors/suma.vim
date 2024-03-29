
" vim:fdm=marker
" Vim Color File
" Name:       suma.vim
" Maintainer: Suma
" License:
" Based On:   https://github.com/joshdick/onedark.vim/

" Color Reference {{{

" The following colors were measured inside Atom using its built-in inspector.

" +---------------------------------------------+
" |  Color Name  |         RGB        |   Hex   |
" |--------------+--------------------+---------|
" | Black        | rgb(40, 44, 52)    | #282c34 |
" |--------------+--------------------+---------|
" | White        | rgb(171, 178, 191) | #abb2bf |
" |--------------+--------------------+---------|
" | Light Red    | rgb(224, 108, 117) | #e06c75 |
" |--------------+--------------------+---------|
" | Dark Red     | rgb(190, 80, 70)   | #be5046 |
" |--------------+--------------------+---------|
" | Green        | rgb(152, 195, 121) | #98c379 |
" |--------------+--------------------+---------|
" | Light Yellow | rgb(229, 192, 123) | #e5c07b |
" |--------------+--------------------+---------|
" | Dark Yellow  | rgb(209, 154, 102) | #d19a66 |
" |--------------+--------------------+---------|
" | Blue         | rgb(97, 175, 239)  | #61afef |
" |--------------+--------------------+---------|
" | Magenta      | rgb(198, 120, 221) | #c678dd |
" |--------------+--------------------+---------|
" | Cyan         | rgb(86, 182, 194)  | #56b6c2 |
" |--------------+--------------------+---------|
" | Gutter Grey  | rgb(76, 82, 99)    | #4b5263 |
" |--------------+--------------------+---------|
" | Comment Grey | rgb(92, 99, 112)   | #5c6370 |
" +---------------------------------------------+

" }}}

" Initialization {{{

highlight clear

if exists("syntax_on")
  syntax reset
endif

let g:colors_name="suma"

" Set to "256" for 256-color terminals, or
" set to "16" to use your terminal emulator's native colors
if !exists("g:suma_termcolors")
  let g:suma_termcolors = 256
endif

" Not all terminals support italics properly. If yours does, opt-in.
if !exists("g:suma_terminal_italics")
  let g:suma_terminal_italics = 1
endif

" This function is based on one from FlatColor: https://github.com/MaxSt/FlatColor/ Which in turn was based on one found in hemisu: https://github.com/noahfrederick/vim-hemisu/
let s:group_colors = {} " Cache of default highlight group settings, for later reference via `suma#extend_highlight`
function! s:h(group, style, ...)
    let l:highlight = a:style
    let s:group_colors[a:group] = l:highlight " Cache default highlight group settings

  if g:suma_terminal_italics == 0
    if has_key(l:highlight, "cterm") && l:highlight["cterm"] == "italic"
      unlet l:highlight.cterm
    endif
    if has_key(l:highlight, "gui") && l:highlight["gui"] == "italic"
      unlet l:highlight.gui
    endif
  endif

  if g:suma_termcolors == 16
    let l:ctermfg = (has_key(l:highlight, "fg") ? l:highlight.fg.cterm16 : "NONE")
    let l:ctermbg = (has_key(l:highlight, "bg") ? l:highlight.bg.cterm16 : "NONE")
  else
    let l:ctermfg = (has_key(l:highlight, "fg") ? l:highlight.fg.cterm : "NONE")
    let l:ctermbg = (has_key(l:highlight, "bg") ? l:highlight.bg.cterm : "NONE")
  endif

  execute "highlight" a:group
    \ "guifg="   (has_key(l:highlight, "fg")    ? l:highlight.fg.gui   : "NONE")
    \ "guibg="   (has_key(l:highlight, "bg")    ? l:highlight.bg.gui   : "NONE")
    \ "guisp="   (has_key(l:highlight, "sp")    ? l:highlight.sp.gui   : "NONE")
    \ "gui="     (has_key(l:highlight, "gui")   ? l:highlight.gui      : "NONE")
    \ "ctermfg=" . l:ctermfg
    \ "ctermbg=" . l:ctermbg
    \ "cterm="   (has_key(l:highlight, "cterm") ? l:highlight.cterm    : "NONE")
endfunction

" }}}

" Color Variables {{{
let s:colors = {
      \ "red":            { "gui": "#E06C75" , "cterm": "204"  , "cterm16": "1" }  ,
      \ "dark_red":       { "gui": "#BE5046" , "cterm": "196"  , "cterm16": "9" }  ,
      \ "green":          { "gui": "#98C379" , "cterm": "114"  , "cterm16": "2" }  ,
      \ "yellow":         { "gui": "#E5C07B" , "cterm": "180"  , "cterm16": "3" }  ,
      \ "dark_yellow":    { "gui": "#D19A66" , "cterm": "173"  , "cterm16": "11" } ,
      \ "blue":           { "gui": "#61AFEF" , "cterm": "39"   , "cterm16": "4" }  ,
      \ "purple":         { "gui": "#C678DD" , "cterm": "170"  , "cterm16": "5" }  ,
      \ "cyan":           { "gui": "#56B6C2" , "cterm": "38"   , "cterm16": "6" }  ,
      \ "white":          { "gui": "#ABB2BF" , "cterm": "145"  , "cterm16": "7" }  ,
      \ "black":          { "gui": "#282C34" , "cterm": "235"  , "cterm16": "0" }  ,
      \ "visual_black":   { "gui": "NONE"    , "cterm": "NONE" , "cterm16": "0" }  ,
      \ "comment_grey":   { "gui": "#5C6370" , "cterm": "59"   , "cterm16": "15" } ,
      \ "gutter_fg_grey": { "gui": "#4B5263" , "cterm": "238"  , "cterm16": "15" } ,
      \ "cursor_grey":    { "gui": "#2C323C" , "cterm": "236"  , "cterm16": "8" }  ,
      \ "visual_grey":    { "gui": "#3E4452" , "cterm": "237"  , "cterm16": "15" } ,
      \ "menu_grey":      { "gui": "#3E4452" , "cterm": "237"  , "cterm16": "8" }  ,
      \ "special_grey":   { "gui": "#3B4048" , "cterm": "238"  , "cterm16": "15" } ,
      \ "vertsplit":      { "gui": "#181A1F" , "cterm": "59"   , "cterm16": "15" } ,
      \}

let s:black =           s:colors.black
let s:red =             s:colors.red
let s:green =           s:colors.green
let s:yellow =          s:colors.yellow
let s:blue =            s:colors.blue
let s:purple =          s:colors.purple
let s:cyan =            s:colors.cyan
let s:visual_grey =     s:colors.visual_grey

let s:comment_grey =    s:colors.comment_grey
let s:dark_red =        s:colors.dark_red
" let s:dark_green =    s:colors.dark_green
let s:dark_yellow =     s:colors.dark_yellow
" let s:dark_blue =     s:colors.dark_blue
" let s:dark_purple =   s:colors.dark_purple
" let s:dark_cyan =     s:colors.dark_cyan
let s:white =           s:colors.white

let s:gutter_fg_grey =  s:colors.gutter_fg_grey
let s:cursor_grey =     s:colors.cursor_grey
let s:vertsplit =       s:colors.vertsplit
let s:visual_black =    s:colors.visual_black " Black out selected text in 16-color visual mode
let s:special_grey =    s:colors.special_grey
let s:menu_grey =       s:colors.menu_grey
" }}}

" Syntax Groups (descriptions and ordering from `:h w18`) {{{

call s:h("Comment", { "fg": s:comment_grey, "gui": "italic", "cterm": "italic" }) " any comment
" call s:h("Constant", { "fg": s:cyan }) " any constant
call s:h("Constant", { "fg": s:dark_yellow }) " any constant
call s:h("String", { "fg": s:green }) " a string constant: "this is a string"
call s:h("Character", { "fg": s:green }) " a character constant: 'c', '\n'
call s:h("Number", { "fg": s:dark_yellow }) " a number constant: 234, 0xff
call s:h("Boolean", { "fg": s:dark_yellow }) " a boolean constant: TRUE, false
call s:h("Float", { "fg": s:dark_yellow }) " a floating point constant: 2.3e10
call s:h("Identifier", { "fg": s:red }) " any variable name
call s:h("Function", { "fg": s:blue }) " function name (also: methods for classes)
" call s:h("Statement", { "fg": s:purple }) " any statement
call s:h("Statement", { "fg": s:red, "gui": "bold", "cterm": "bold" }) " any statement
call s:h("Conditional", { "fg": s:purple }) " if, then, else, endif, switch, etc.
call s:h("Repeat", { "fg": s:purple }) " for, do, while, etc.
call s:h("Label", { "fg": s:purple }) " case, default, etc.
call s:h("Operator", { "fg": s:purple }) " sizeof", "+", "*", etc.
call s:h("Keyword", { "fg": s:red }) " any other keyword
call s:h("Exception", { "fg": s:purple }) " try, catch, throw
call s:h("PreProc", { "fg": s:yellow }) " generic Preprocessor
call s:h("Include", { "fg": s:blue }) " preprocessor #include
call s:h("Define", { "fg": s:purple }) " preprocessor #define
call s:h("Macro", { "fg": s:purple }) " same as Define
call s:h("PreCondit", { "fg": s:yellow }) " preprocessor #if, #else, #endif, etc.
call s:h("Type", { "fg": s:yellow }) " int, long, char, etc.
call s:h("StorageClass", { "fg": s:yellow }) " static, register, volatile, etc.
call s:h("Structure", { "fg": s:yellow }) " struct, union, enum, etc.
call s:h("Typedef", { "fg": s:yellow }) " A typedef
" call s:h("Special", { "fg": s:blue }) " any special symbol
call s:h("Special", { "fg": s:green }) " any special symbol
" call s:h("SpecialChar", {}) " special character in a constant
call s:h("SpecialChar", {"fg": s:dark_red }) " special character in a constant
call s:h("Tag", {}) " you can use CTRL-] on this
" call s:h("Delimiter", {}) " character that needs attention
call s:h("Delimiter", { "fg": s:dark_yellow }) " character that needs attention
" call s:h("SpecialComment", { "fg": s:comment_grey }) " special things inside a comment
call s:h("SpecialComment", { "fg": s:cyan }) " special things inside a comment
call s:h("Debug", {}) " debugging statements
call s:h("Underlined", { "gui": "underline", "cterm": "underline" }) " text that stands out, HTML links
call s:h("Ignore", {}) " left blank, hidden
call s:h("Error", { "fg": s:red }) " any erroneous construct
call s:h("Todo", { "fg": s:yellow, "gui": "bold", "cterm": "bold" }) " anything that needs extra attention; mostly the keywords TODO FIXME and XXX

" }}}

" Highlighting Groups (descriptions and ordering from `:h highlight-groups`) {{{
call s:h("ColorColumn",  { "bg": s:cursor_grey                                   } ) " used for the columns set with 'colorcolumn
call s:h("Conceal",      { } ) " placeholder characters substituted for concealed text (see 'conceallevel'
call s:h("Cursor",       { "fg": s:black, "bg": s:blue                           } ) " the character under the cursor
call s:h("CursorIM",     { } ) " like Cursor but used when in IME mod
call s:h("CursorColumn", { "bg": s:cursor_grey                                   } ) " the screen column that the cursor is in when 'cursorcolumn' is se
if &diff
  call s:h("CursorLine", { "cterm": "underline", "gui": "underline"              } ) " the screen line that the cursor is in when 'cursorline' is set
els
  call s:h("CursorLine", { "bg": s:cursor_grey                                   } ) " the screen line that the cursor is in when 'cursorline' is se
endi
call s:h("Directory",    { "fg": s:blue                                          } ) " directory names (and other special names in listings
call s:h("DiffAdd",      { "bg": s:special_grey                                  } ) " diff mode: Added lin
call s:h("DiffChange",   { "bg": s:black                                         } ) " diff mode: Changed lin
call s:h("DiffDelete",   { "bg": s:special_grey, "fg": s:special_grey            } ) " diff mode: Deleted lin
call s:h("DiffText",     { "bg": s:blue, "fg": s:black                           } ) " diff mode: Changed text within a changed lin
call s:h("Error",        { "bg": s:red, "fg": s:black                            } ) " error messages on the command lin
call s:h("ErrorMsg",     { "fg": s:red                                           } ) " error messages on the command lin
call s:h("VertSplit",    { "fg": s:vertsplit                                     } ) " the column separating vertically split window
call s:h("Folded",       { "fg": s:comment_grey                                  } ) " line used for closed fold
call s:h("FoldColumn",   { } ) " 'foldcolumn
call s:h("SignColumn",   { } ) " column where signs are displaye
call s:h("IncSearch",    { "fg": s:yellow, "bg": s:comment_grey                  } ) " 'incsearch' highlighting; also used for the text replaced with ':s///c'
call s:h("LineNr",       { "fg": s:gutter_fg_grey                                } ) " Line number for ':number' and ':#' commands and when 'number' or 'relativenumber' option is set
call s:h("CursorLineNr", { } ) " Like LineNr when 'cursorline' or 'relativenumber' is set for the cursor line
call s:h("MatchParen",   { "fg": s:blue, "gui": "bold"                           } ) " The character under the cursor or just before it if it is a paired bracket and its match
call s:h("ModeMsg",      { } ) " 'showmode' message (e.g. -- INSERT --)
call s:h("MoreMsg",      { } ) " more-promp
call s:h("NonText",      { "fg": s:special_grey                                  } ) " '~' and '@' at the end of the window characters from 'showbreak' and other characters that do not really exist in the text (e.g. '>' displayed when a double-wide character doesn't fit at the end of the line)
call s:h("Normal",       { "fg": s:white, "bg": s:black                          } ) " normal tex
call s:h("Pmenu",        { "bg": s:menu_grey                                     } ) " Popup menu: normal item
call s:h("PmenuSel",     { "fg": s:black, "bg": s:blue                           } ) " Popup menu: selected item
call s:h("PmenuSbar",    { "bg": s:special_grey                                  } ) " Popup menu: scrollbar
call s:h("PmenuThumb",   { "bg": s:white                                         } ) " Popup menu: Thumb of the scrollbar
call s:h("Question",     { "fg": s:purple                                        } ) " hit-enter prompt and yes/no question
call s:h("Search",       { "fg": s:black, "bg": s:yellow                         } ) " Last search pattern highlighting (see 'hlsearch'). Also used for similar items that need to stand out
call s:h("QuickFixLine", { "fg": s:black, "bg": s:yellow                         } ) " Current quickfix item in the quickfix window
call s:h("SpecialKey",   { "fg": s:special_grey                                  } ) " Meta and special keys listed with ':map' also for text used to show unprintable characters in the text 'listchars'. Generally: text that is displayed differently from what it really is
call s:h("SpellBad",     { "fg": s:red, "gui": "underline", "cterm": "underline" } ) " Word that is not recognized by the spellchecker. This will be combined with the highlighting used otherwise
call s:h("SpellCap",     { "fg": s:dark_yellow                                   } ) " Word that should start with a capital. This will be combined with the highlighting used otherwise
call s:h("SpellLocal",   { "fg": s:dark_yellow                                   } ) " Word that is recognized by the spellchecker as one that is used in another region. This will be combined with the highlighting used otherwise
call s:h("SpellRare",    { "fg": s:dark_yellow                                   } ) " Word that is recognized by the spellchecker as one that is hardly ever used. spell This will be combined with the highlighting used otherwise
call s:h("StatusLine",   { "fg": s:white, "bg": s:cursor_grey                    } ) " status line of current windo
call s:h("StatusLineNC", { "fg": s:comment_grey                                  } ) " status lines of not-current windows Note: if this is equal to 'StatusLine' Vim will use '^^^' in the status line of the current window
call s:h("TabLine",      { "fg": s:comment_grey                                  } ) " tab pages line                                                                                                                                                                                                                                                                                                                                              not active tab page label
call s:h("TabLineFill",  { } ) " tab pages line, where there are no label
call s:h("TabLineSel",   { "fg": s:white                                         } ) " tab pages line active tab page labe
call s:h("Title",        { "fg": s:green                                         } ) " titles for output from ':set all' ':autocmd' etc.
call s:h("Visual",       { "fg": s:visual_black, "bg": s:visual_grey             } ) " Visual mode selectio
call s:h("VisualNOS",    { "bg": s:visual_grey                                   } ) " Visual mode selection when vim is 'Not Owning the Selection'. Only X11 Gui's gui-x11 and xterm-clipboard supports this
call s:h("WarningMsg",   { "fg": s:yellow                                        } ) " warning message
call s:h("WildMenu",     { "fg": s:black, "bg": s:blue                           } ) " current match in 'wildmenu' completion

" }}}

" Language-Specific Highlighting {{{

" CSS
call s:h("cssAttrComma",         { "fg": s:purple })
call s:h("cssAttributeSelector", { "fg": s:green })
call s:h("cssBraces",            { "fg": s:white })
call s:h("cssClassName",         { "fg": s:dark_yellow })
call s:h("cssClassNameDot",      { "fg": s:dark_yellow })
call s:h("cssDefinition",        { "fg": s:purple })
call s:h("cssFontAttr",          { "fg": s:dark_yellow })
call s:h("cssFontDescriptor",    { "fg": s:purple })
call s:h("cssFunctionName",      { "fg": s:blue })
call s:h("cssIdentifier",        { "fg": s:blue })
call s:h("cssImportant",         { "fg": s:purple })
call s:h("cssInclude",           { "fg": s:white })
call s:h("cssIncludeKeyword",    { "fg": s:purple })
call s:h("cssMediaType",         { "fg": s:dark_yellow })
call s:h("cssProp",              { "fg": s:white })
call s:h("cssPseudoClassId",     { "fg": s:dark_yellow })
call s:h("cssSelectorOp",        { "fg": s:purple })
call s:h("cssSelectorOp2",       { "fg": s:purple })
call s:h("cssTagName",           { "fg": s:red })

" Go
call s:h("goDeclaration", { "fg": s:purple })

" HTML
call s:h("htmlTitle",          { "fg": s:white })
call s:h("htmlArg",            { "fg": s:dark_yellow })
call s:h("htmlEndTag",         { "fg": s:white })
call s:h("htmlH1",             { "fg": s:white })
call s:h("htmlLink",           { "fg": s:purple })
call s:h("htmlSpecialChar",    { "fg": s:dark_yellow })
call s:h("htmlSpecialTagName", { "fg": s:red })
call s:h("htmlTag",            { "fg": s:white })
call s:h("htmlTagName",        { "fg": s:red })

" JavaScript
call s:h("javaScriptBraces",     { "fg": s:white })
call s:h("javaScriptFunction",   { "fg": s:purple })
call s:h("javaScriptIdentifier", { "fg": s:purple })
call s:h("javaScriptNull",       { "fg": s:dark_yellow })
call s:h("javaScriptNumber",     { "fg": s:dark_yellow })
call s:h("javaScriptRequire",    { "fg": s:cyan })
call s:h("javaScriptReserved",   { "fg": s:purple })
" https://github.com/pangloss/vim-javascript
call s:h("jsArrowFunction",   { "fg": s:purple })
call s:h("jsClassKeyword",    { "fg": s:purple })
call s:h("jsClassMethodType", { "fg": s:purple })
call s:h("jsDocParam",        { "fg": s:blue })
call s:h("jsDocTags",         { "fg": s:purple })
call s:h("jsExport",          { "fg": s:purple })
call s:h("jsExportDefault",   { "fg": s:purple })
call s:h("jsExtendsKeyword",  { "fg": s:purple })
call s:h("jsFrom",            { "fg": s:purple })
call s:h("jsFuncCall",        { "fg": s:blue })
call s:h("jsFunction",        { "fg": s:purple })
call s:h("jsGenerator",       { "fg": s:yellow })
call s:h("jsGlobalObjects",   { "fg": s:yellow })
call s:h("jsImport",          { "fg": s:purple })
call s:h("jsModuleAs",        { "fg": s:purple })
call s:h("jsModuleWords",     { "fg": s:purple })
call s:h("jsModules",         { "fg": s:purple })
call s:h("jsNull",            { "fg": s:dark_yellow })
call s:h("jsOperator",        { "fg": s:purple })
call s:h("jsStorageClass",    { "fg": s:purple })
call s:h("jsSuper",           { "fg": s:red })
call s:h("jsTemplateBraces",  { "fg": s:dark_red })
call s:h("jsTemplateVar",     { "fg": s:green })
call s:h("jsThis",            { "fg": s:red })
call s:h("jsUndefined",       { "fg": s:dark_yellow })
" https://github.com/othree/yajs.vim
call s:h("javascriptArrowFunc",    { "fg": s:purple })
call s:h("javascriptClassExtends", { "fg": s:purple })
call s:h("javascriptClassKeyword", { "fg": s:purple })
call s:h("javascriptDocNotation",  { "fg": s:purple })
call s:h("javascriptDocParamName", { "fg": s:blue })
call s:h("javascriptDocTags",      { "fg": s:purple })
call s:h("javascriptEndColons",    { "fg": s:white })
call s:h("javascriptExport",       { "fg": s:purple })
call s:h("javascriptFuncArg",      { "fg": s:white })
call s:h("javascriptFuncKeyword",  { "fg": s:purple })
call s:h("javascriptIdentifier",   { "fg": s:red })
call s:h("javascriptImport",       { "fg": s:purple })
call s:h("javascriptMethodName",   { "fg": s:white })
call s:h("javascriptObjectLabel",  { "fg": s:white })
call s:h("javascriptOpSymbol",     { "fg": s:cyan })
call s:h("javascriptOpSymbols",    { "fg": s:cyan })
call s:h("javascriptPropertyName", { "fg": s:green })
call s:h("javascriptTemplateSB",   { "fg": s:dark_red })
call s:h("javascriptVariable",     { "fg": s:purple })

" JSON
call s:h("jsonCommentError",      { "fg": s:white })
call s:h("jsonKeyword",           { "fg": s:red })
call s:h("jsonBoolean",           { "fg": s:dark_yellow })
call s:h("jsonNumber",            { "fg": s:dark_yellow })
call s:h("jsonQuote",             { "fg": s:white })
call s:h("jsonMissingCommaError", { "fg": s:red, "gui": "reverse" })
call s:h("jsonNoQuotesError",     { "fg": s:red, "gui": "reverse" })
call s:h("jsonNumError",          { "fg": s:red, "gui": "reverse" })
call s:h("jsonString",            { "fg": s:green })
call s:h("jsonStringSQError",     { "fg": s:red, "gui": "reverse" })
call s:h("jsonSemicolonError",    { "fg": s:red, "gui": "reverse" })

" LESS
call s:h("lessVariable",      { "fg": s:purple })
call s:h("lessAmpersandChar", { "fg": s:white })
call s:h("lessClass",         { "fg": s:dark_yellow })

" Markdown
call s:h("markdownCode",              { "fg": s:green })
call s:h("markdownCodeBlock",         { "fg": s:green })
call s:h("markdownCodeDelimiter",     { "fg": s:green })
call s:h("markdownHeadingDelimiter",  { "fg": s:red })
call s:h("markdownRule",              { "fg": s:comment_grey })
call s:h("markdownHeadingRule",       { "fg": s:comment_grey })
call s:h("markdownH1",                { "fg": s:red })
call s:h("markdownH2",                { "fg": s:red })
call s:h("markdownH3",                { "fg": s:red })
call s:h("markdownH4",                { "fg": s:red })
call s:h("markdownH5",                { "fg": s:red })
call s:h("markdownH6",                { "fg": s:red })
call s:h("markdownIdDelimiter",       { "fg": s:purple })
call s:h("markdownId",                { "fg": s:purple })
call s:h("markdownBlockquote",        { "fg": s:comment_grey })
call s:h("markdownItalic",            { "fg": s:purple, "gui": "italic", "cterm": "italic" })
call s:h("markdownBold",              { "fg": s:dark_yellow, "gui": "bold", "cterm": "bold" })
call s:h("markdownListMarker",        { "fg": s:red })
call s:h("markdownOrderedListMarker", { "fg": s:red })
call s:h("markdownIdDeclaration",     { "fg": s:blue })
call s:h("markdownLinkText",          { "fg": s:blue })
call s:h("markdownLinkDelimiter",     { "fg": s:white })
call s:h("markdownUrl",               { "fg": s:purple })

" Perl
call s:h("perlFiledescRead",      { "fg": s:green })
call s:h("perlFunction",          { "fg": s:purple })
call s:h("perlMatchStartEnd",     { "fg": s:blue })
call s:h("perlMethod",            { "fg": s:purple })
call s:h("perlPOD",               { "fg": s:comment_grey })
call s:h("perlSharpBang",         { "fg": s:comment_grey })
call s:h("perlSpecialString",     { "fg": s:cyan })
call s:h("perlStatementFiledesc", { "fg": s:red })
call s:h("perlStatementFlow",     { "fg": s:red })
call s:h("perlStatementInclude",  { "fg": s:purple })
call s:h("perlStatementScalar",   { "fg": s:purple })
call s:h("perlStatementStorage",  { "fg": s:purple })
call s:h("perlSubName",           { "fg": s:yellow })
call s:h("perlVarPlain",          { "fg": s:blue })

" PHP
call s:h("phpVarSelector",    { "fg": s:red })
call s:h("phpOperator",       { "fg": s:white })
call s:h("phpParent",         { "fg": s:white })
call s:h("phpMemberSelector", { "fg": s:white })
call s:h("phpType",           { "fg": s:purple })
call s:h("phpKeyword",        { "fg": s:purple })
call s:h("phpClass",          { "fg": s:yellow })
call s:h("phpUseClass",       { "fg": s:white })
call s:h("phpUseAlias",       { "fg": s:white })
call s:h("phpInclude",        { "fg": s:purple })
call s:h("phpClassExtends",   { "fg": s:green })
call s:h("phpDocTags",        { "fg": s:white })
call s:h("phpFunction",       { "fg": s:blue })
call s:h("phpFunctions",      { "fg": s:cyan })
call s:h("phpMethodsVar",     { "fg": s:dark_yellow })
call s:h("phpMagicConstants", { "fg": s:dark_yellow })
call s:h("phpSuperglobals",   { "fg": s:red })
call s:h("phpConstants",      { "fg": s:dark_yellow })

" Ruby
call s:h("rubyBlockParameter",            { "fg": s:red})
call s:h("rubyBlockParameterList",        { "fg": s:red })
call s:h("rubyClass",                     { "fg": s:purple})
call s:h("rubyConstant",                  { "fg": s:yellow})
call s:h("rubyControl",                   { "fg": s:purple })
call s:h("rubyEscape",                    { "fg": s:red})
call s:h("rubyFunction",                  { "fg": s:blue})
call s:h("rubyGlobalVariable",            { "fg": s:red})
call s:h("rubyInclude",                   { "fg": s:blue})
call s:h("rubyIncluderubyGlobalVariable", { "fg": s:red})
call s:h("rubyInstanceVariable",          { "fg": s:red})
call s:h("rubyInterpolation",             { "fg": s:cyan })
call s:h("rubyInterpolationDelimiter",    { "fg": s:red })
call s:h("rubyInterpolationDelimiter",    { "fg": s:red})
call s:h("rubyRegexp",                    { "fg": s:cyan})
call s:h("rubyRegexpDelimiter",           { "fg": s:cyan})
call s:h("rubyStringDelimiter",           { "fg": s:green})
call s:h("rubySymbol",                    { "fg": s:cyan})

" Sass
" https://github.com/tpope/vim-haml
call s:h("sassAmpersand",      { "fg": s:red })
call s:h("sassClass",          { "fg": s:dark_yellow })
call s:h("sassControl",        { "fg": s:purple })
call s:h("sassExtend",         { "fg": s:purple })
call s:h("sassFor",            { "fg": s:white })
call s:h("sassFunction",       { "fg": s:cyan })
call s:h("sassId",             { "fg": s:blue })
call s:h("sassInclude",        { "fg": s:purple })
call s:h("sassMedia",          { "fg": s:purple })
call s:h("sassMediaOperators", { "fg": s:white })
call s:h("sassMixin",          { "fg": s:purple })
call s:h("sassMixinName",      { "fg": s:blue })
call s:h("sassMixing",         { "fg": s:purple })
call s:h("sassVariable",       { "fg": s:purple })
" https://github.com/cakebaker/scss-syntax.vim
call s:h("scssExtend",       { "fg": s:purple })
call s:h("scssImport",       { "fg": s:purple })
call s:h("scssInclude",      { "fg": s:purple })
call s:h("scssMixin",        { "fg": s:purple })
call s:h("scssSelectorName", { "fg": s:dark_yellow })
call s:h("scssVariable",     { "fg": s:purple })

" TypeScript
call s:h("typescriptReserved",  { "fg": s:purple })
call s:h("typescriptEndColons", { "fg": s:white })
call s:h("typescriptBraces",    { "fg": s:white })

" XML
call s:h("xmlAttrib",  { "fg": s:dark_yellow })
call s:h("xmlEndTag",  { "fg": s:red })
call s:h("xmlTag",     { "fg": s:red })
call s:h("xmlTagName", { "fg": s:red })

" }}}

" Plugin Highlighting {{{

" airblade/vim-gitgutter
hi link GitGutterAdd    SignifySignAdd
hi link GitGutterChange SignifySignChange
hi link GitGutterDelete SignifySignDelete

" easymotion/vim-easymotion
call s:h("EasyMotionTarget",        { "fg": s:red, "gui": "bold", "cterm": "bold" })
call s:h("EasyMotionTarget2First",  { "fg": s:yellow, "gui": "bold", "cterm": "bold" })
call s:h("EasyMotionTarget2Second", { "fg": s:dark_yellow, "gui": "bold", "cterm": "bold" })
call s:h("EasyMotionShade",         { "fg": s:comment_grey })

" mhinz/vim-signify
call s:h("SignifySignAdd",    { "fg": s:green })
call s:h("SignifySignChange", { "fg": s:yellow })
call s:h("SignifySignDelete", { "fg": s:red })

" neomake/neomake
call s:h("NeomakeWarningSign", { "fg": s:yellow })
call s:h("NeomakeErrorSign",   { "fg": s:red })
call s:h("NeomakeInfoSign",    { "fg": s:blue })

" tpope/vim-fugitive
call s:h("diffAdded",   { "fg": s:green })
call s:h("diffRemoved", { "fg": s:red })

" }}}

" Git Highlighting {{{

call s:h("gitcommitComment",       { "fg": s:comment_grey })
call s:h("gitcommitUnmerged",      { "fg": s:green })
call s:h("gitcommitOnBranch",      { })
call s:h("gitcommitBranch",        { "fg": s:purple })
call s:h("gitcommitDiscardedType", { "fg": s:red })
call s:h("gitcommitSelectedType",  { "fg": s:green })
call s:h("gitcommitHeader",        { })
call s:h("gitcommitUntrackedFile", { "fg": s:cyan })
call s:h("gitcommitDiscardedFile", { "fg": s:red })
call s:h("gitcommitSelectedFile",  { "fg": s:green })
call s:h("gitcommitUnmergedFile",  { "fg": s:yellow })
call s:h("gitcommitFile",          { })
call s:h("gitcommitSummary",       { "fg": s:white })
call s:h("gitcommitOverflow",      { "fg": s:red })
hi link gitcommitNoBranch gitcommitBranch
hi link gitcommitUntracked gitcommitComment
hi link gitcommitDiscarded gitcommitComment
hi link gitcommitSelected gitcommitComment
hi link gitcommitDiscardedArrow gitcommitDiscardedFile
hi link gitcommitSelectedArrow gitcommitSelectedFile
hi link gitcommitUnmergedArrow gitcommitUnmergedFile

" }}}

" Neovim terminal colors {{{

if has("nvim")
  let g:terminal_color_0          = s:black.gui
  let g:terminal_color_1          = s:red.gui
  let g:terminal_color_2          = s:green.gui
  let g:terminal_color_3          = s:yellow.gui
  let g:terminal_color_4          = s:blue.gui
  let g:terminal_color_5          = s:purple.gui
  let g:terminal_color_6          = s:cyan.gui
  let g:terminal_color_7          = s:white.gui
  let g:terminal_color_8          = s:visual_grey.gui
  let g:terminal_color_9          = s:dark_red.gui
  let g:terminal_color_10         = s:green.gui " No dark version
  let g:terminal_color_11         = s:dark_yellow.gui
  let g:terminal_color_12         = s:blue.gui " No dark version
  let g:terminal_color_13         = s:purple.gui " No dark version
  let g:terminal_color_14         = s:cyan.gui " No dark version
  let g:terminal_color_15         = s:comment_grey.gui
  let g:terminal_color_background = g:terminal_color_0
  let g:terminal_color_foreground = g:terminal_color_7
endif

" }}}

" Must appear at the end of the file to work around this oddity:
" https://groups.google.com/forum/#!msg/vim_dev/afPqwAFNdrU/nqh6tOM87QUJ
set background=dark
