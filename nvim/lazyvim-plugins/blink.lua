-- LazyVim already ships a full blink.cmp config (sources, keymap preset,
-- fuzzy settings). Unlike the standalone init_plugins.lua this is ported
-- from, `opts` here must compose onto LazyVim's own via the (plugin, opts)
-- function form instead of returning a fresh table, or it would silently
-- replace LazyVim's keymap/source setup instead of just layering on top.
return {
    {
        "saghen/blink.cmp",
        opts = function(_, opts)
            vim.g.blink_cmp_auto_trigger = false
            vim.keymap.set("n", "<F2>", function()
                vim.g.blink_cmp_auto_trigger = not vim.g.blink_cmp_auto_trigger
                local ok, blink = pcall(require, "blink.cmp")
                if ok and blink and type(blink.setup) == "function" then
                    blink.setup(vim.tbl_deep_extend("force", opts, {
                        completion = {
                            trigger = {
                                show_on_keyword = vim.g.blink_cmp_auto_trigger,
                                show_on_trigger_character = vim.g.blink_cmp_auto_trigger,
                            },
                        },
                    }))
                end
                print("Completion auto-trigger: " .. (vim.g.blink_cmp_auto_trigger and "ON" or "OFF"))
            end, { desc = "Toggle completion auto-trigger" })

            return vim.tbl_deep_extend("force", opts, {
                completion = {
                    documentation = { auto_show = true },
                    trigger = { show_on_keyword = false, show_on_trigger_character = false },
                },
            })
        end,
    },
}
