-- Replaces LazyVim's default gitsigns keymaps with this setup's own scheme.
return {
    {
        "lewis6991/gitsigns.nvim",
        opts = {
            on_attach = function(bufnr)
                local gs = package.loaded.gitsigns
                local function m(mode, lhs, rhs, desc) vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc }) end
                m("n", "]c", function() if vim.wo.diff then vim.cmd.normal({ "]c", bang = true }) else gs.nav_hunk("next") end end, "Next hunk")
                m("n", "[c", function() if vim.wo.diff then vim.cmd.normal({ "[c", bang = true }) else gs.nav_hunk("prev") end end, "Prev hunk")
                m("n", "<leader>ha", gs.stage_hunk, "Stage hunk")
                m("n", "<leader>hu", gs.undo_stage_hunk, "Undo stage hunk")
                m("n", "<leader>hr", gs.reset_hunk, "Reset hunk")
                m("n", "<leader>ga", gs.stage_buffer, "Stage file")
                m("n", "<leader>gu", function()
                    local file = vim.fn.shellescape(vim.api.nvim_buf_get_name(0))
                    if vim.fn.system("git restore --staged " .. file) == "" then gs.refresh(); print("Unstaged file") else print("Failed to unstage") end
                end, "Unstage file")
                m("n", "<leader>gr", gs.reset_buffer, "Reset file")
                m("n", "<leader>hp", gs.preview_hunk, "Preview hunk")
                m("n", "<leader>gb", function() gs.blame_line({ full = true }) end, "Blame line")
                m("n", "<leader>hd", gs.diffthis, "Diff this")
            end,
        },
    },
}
