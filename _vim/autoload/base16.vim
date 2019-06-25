
let s:overrides = get(g:, "colors_overrides", {})

let s:colors = {
            \ "visual_black": get(s:overrides,    "visual_black",    { "gui": "NONE",     "cterm": "NONE",  "cterm16": "0" }),
            \ "black": get(s:overrides,           "black",           { "gui": "#181818",  "cterm": "235",   "cterm16": "0" }),
            \ "red": get(s:overrides,             "red",             { "gui": "#ab4642",  "cterm": "204",   "cterm16": "1" }),
            \ "green": get(s:overrides,           "green",           { "gui": "#a1b56c",  "cterm": "114",   "cterm16": "2" }),
            \ "yellow": get(s:overrides,          "yellow",          { "gui": "#f7ca88",  "cterm": "180",   "cterm16": "3" }),
            \ "blue": get(s:overrides,            "blue",            { "gui": "#7cafc2",  "cterm": "39",    "cterm16": "4" }),
            \ "purple": get(s:overrides,          "purple",          { "gui": "#ba8baf",  "cterm": "170",   "cterm16": "5" }),
            \ "cyan": get(s:overrides,            "cyan",            { "gui": "#86c1b9",  "cterm": "38",    "cterm16": "6" }),
            \ "white": get(s:overrides,           "white",           { "gui": "#d8d8d8",  "cterm": "145",   "cterm16": "7" }),
            \ "comment_grey": get(s:overrides,    "comment_grey",    { "gui": "#585858",  "cterm": "59",    "cterm16": "8" }),
            \ "dark_red": get(s:overrides,        "dark_red",        { "gui": "#a15646",  "cterm": "196",   "cterm16": "9" }),
            \ "dark_green": get(s:overrides,      "dark_green",      { "gui": "",         "cterm": "",      "cterm16": "10" }),
            \ "dark_yellow": get(s:overrides,     "dark_yellow",     { "gui": "#dc9656",  "cterm": "173",   "cterm16": "11" }),
            \ "dark_blue": get(s:overrides,       "dark_blue",       { "gui": "",         "cterm": "",      "cterm16": "12" }),
            \ "dark_purple": get(s:overrides,     "dark_purple",     { "gui": "",         "cterm": "",      "cterm16": "13" }),
            \ "dark_cyan": get(s:overrides,       "dark_cyan",       { "gui": "",         "cterm": "",      "cterm16": "14" }),
            \ "special_grey": get(s:overrides,    "special_grey",    { "gui": "#f8f8f8",  "cterm": "238",   "cterm16": "15" }),
            \ "gutter_fg_grey": get(s:overrides,  "gutter_fg_grey",  { "gui": "#585858",  "cterm": "238",   "cterm16": "15" }),
            \ "visual_grey": get(s:overrides,     "visual_grey",     { "gui": "#383838",  "cterm": "237",   "cterm16": "8" }),
            \ "menu_grey": get(s:overrides,       "menu_grey",       { "gui": "#383838",  "cterm": "237",   "cterm16": "8" }),
            \ "cursor_grey": get(s:overrides,     "cursor_grey",     { "gui": "#202020",  "cterm": "236",   "cterm16": "8" }),
            \ "vertsplit": get(s:overrides,       "vertsplit",       { "gui": "#080808",  "cterm": "59",    "cterm16": "8" }),
\}

function! base16#GetColors()
  return s:colors
endfunction

