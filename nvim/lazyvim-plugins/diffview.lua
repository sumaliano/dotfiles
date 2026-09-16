-- Not part of LazyVim by default — added fresh, unlike the other overlay
-- files here which only override opts/keys on plugins LazyVim already ships.
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
        opts = { enhanced_diff_hl = true, view = { default = { layout = "diff2_horizontal" } } },
    },
}
