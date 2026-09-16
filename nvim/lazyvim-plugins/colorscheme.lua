-- Real gruvbox.nvim (not the native "gruvbox" the portable init.lua falls
-- back to), matching the contrast/italics this setup has always used.
return {
    {
        "ellisonleao/gruvbox.nvim",
        lazy = false,
        priority = 1000,
        opts = { contrast = "hard", italic = { strings = false, comments = false, operators = false, folds = false } },
    },
    { "LazyVim/LazyVim", opts = { colorscheme = "gruvbox" } },
}
