-- Not part of LazyVim by default — added fresh, unlike colorscheme.lua which
-- only overrides opts on a plugin LazyVim already ships.
return {
    {
        "sindrets/diffview.nvim",
        cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory" },
        dependencies = { "nvim-lua/plenary.nvim" },
        keys = {
            { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Diff open" },
            { "q",          "<cmd>DiffviewClose<cr>", desc = "Diff close" },
            { "<leader>gl", "<cmd>DiffviewFileHistory %<cr>", desc = "File history" },
            { "<leader>gh", "<cmd>DiffviewFileHistory<cr>", desc = "Branch history" },
        },
        opts = {
            enhanced_diff_hl = true,
            -- diff2_horizontal = side-by-side diff panes (named for the split
            -- direction, not the visual result — see :h diffview-config-view).
            view = { default = { layout = "diff2_horizontal" } },
            -- File tree at the bottom instead of the default left sidebar.
            file_panel = { win_config = { position = "bottom", height = 15 } },
        },
    },
}
