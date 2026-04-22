-- ============================================================================
-- NEVIM FULL CONFIGURATION (Plugin-Based)
-- ============================================================================

require('core')

-- ============================================================================
-- BOOTSTRAP lazy.nvim
-- ============================================================================

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git", "clone", "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

-- ============================================================================
-- PLUGINS
-- ============================================================================

require("lazy").setup({
    {
        "ellisonleao/gruvbox.nvim",
        lazy = false,
        priority = 1000,
        opts = { contrast = "hard", italic = { strings = false, comments = false, operators = false, folds = false } },
        config = function(_, opts)
            require("gruvbox").setup(opts)
            vim.cmd.colorscheme("gruvbox")
        end,
    },
    { "stevearc/dressing.nvim", opts = {} },
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        event = { "BufReadPost", "BufNewFile" },
        opts = {
            ensure_installed = { "lua", "vim", "vimdoc", "python", "rust", "bash", "c", "cpp", "java", "json", "yaml", "markdown", "markdown_inline" },
            highlight = { enable = true },
            indent = { enable = true },
            incremental_selection = {
                enable = true,
                keymaps = { init_selection = "<C-space>", node_incremental = "<C-space>", node_decremental = "<bs>" },
            },
        },
        config = function(_, opts) require("nvim-treesitter.configs").setup(opts) end,
    },
    {
        "mason-org/mason.nvim",
        cmd = "Mason",
        build = ":MasonUpdate",
        keys = { { "<leader>cm", "<cmd>Mason<cr>", desc = "Mason" } },
        opts = {},
    },
    {
        "mason-org/mason-lspconfig.nvim",
        lazy = true,
        opts = { ensure_installed = { "lua_ls", "pyright", "rust_analyzer", "clangd", "jdtls", "bashls", "jsonls", "yamlls" } },
    },
    {
        "saghen/blink.cmp",
        version = "1.*",
        event = "InsertEnter",
        opts = function()
            vim.g.blink_cmp_auto_trigger = false
            vim.keymap.set("n", "<F2>", function()
                vim.g.blink_cmp_auto_trigger = not vim.g.blink_cmp_auto_trigger
                local ok, blink = pcall(require, "blink.cmp")
                if ok and blink and type(blink.setup) == "function" then
                    blink.setup({ completion = { trigger = { show_on_keyword = vim.g.blink_cmp_auto_trigger, show_on_trigger_character = vim.g.blink_cmp_auto_trigger } } })
                end
                print("Completion auto-trigger: " .. (vim.g.blink_cmp_auto_trigger and "ON" or "OFF"))
            end, { desc = "Toggle completion auto-trigger" })

            return {
                completion = { documentation = { auto_show = true }, trigger = { show_on_keyword = false, show_on_trigger_character = false } },
                sources = { default = { "lsp", "path", "buffer" } },
            }
        end,
    },
    {
        "nvim-telescope/telescope.nvim",
        cmd = "Telescope",
        dependencies = { "nvim-lua/plenary.nvim" },
        keys = {
            { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find files" },
            { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Search in files" },
            { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffer list" },
            { "<leader>fr", "<cmd>Telescope oldfiles<cr>", desc = "Recent files" },
            { "<leader>fm", "<cmd>Telescope marks<cr>", desc = "Marks list" },
            { "<leader>fs", "<cmd>Telescope lsp_document_symbols<cr>", desc = "Symbols" },
        },
    },
}, { rocks = { enabled = false }, checker = { enabled = true } })

-- ============================================================================
-- NATIVE LSP (Full Setup)
-- ============================================================================

vim.env.PATH = vim.fn.stdpath("data") .. "/mason/bin:" .. vim.env.PATH
vim.lsp.config("*", { capabilities = require("blink.cmp").get_lsp_capabilities() })
vim.lsp.enable({ "lua_ls", "pyright", "rust_analyzer", "clangd", "bashls", "jsonls", "yamlls" })

vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(ev)
        local m = function(mode, lhs, rhs, desc) vim.keymap.set(mode, lhs, rhs, { buffer = ev.buf, silent = true, desc = desc }) end
        m("n", "gd", vim.lsp.buf.definition, "Definition")
        m("n", "grr", vim.lsp.buf.references, "References")
        m("n", "K", vim.lsp.buf.hover, "Hover")
        m("n", "grn", vim.lsp.buf.rename, "Rename")
        m("n", "gra", vim.lsp.buf.code_action, "Code action")
        m("n", "grf", function() vim.lsp.buf.format({ async = true }) end, "Format")
    end,
})

-- ============================================================================
-- GIT CONFLICTS
-- ============================================================================

local function resolve_conflict(choice)
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local cur = vim.api.nvim_win_get_cursor(0)[1]
    local s, m, e, f
    for i = cur, 1, -1 do if lines[i]:match("^<<<<<<<") then s = i; break end end
    if not s then return print("Not in conflict") end
    for i = s, #lines do
        if lines[i]:match("^|||||||") then m = i elseif lines[i]:match("^=======") then e = i elseif lines[i]:match("^>>>>>>>") then f = i; break end
    end
    if not e or not f then return print("Malformed conflict") end
    local ranges = { ours = { s + 1, (m or e) - 1 }, theirs = { e + 1, f - 1 }, base = m and { m + 1, e - 1 } }
    local range = ranges[choice]
    if not range then return print("No base section") end
    local result = {}
    for i = range[1], range[2] do table.insert(result, lines[i]) end
    vim.api.nvim_buf_set_lines(0, s - 1, f, false, result)
    print("Resolved: " .. choice)
end

vim.keymap.set("n", "gH", function() resolve_conflict("ours") end, { desc = "Resolve: OURS" })
vim.keymap.set("n", "gJ", function() resolve_conflict("base") end, { desc = "Resolve: BASE" })
vim.keymap.set("n", "gL", function() resolve_conflict("theirs") end, { desc = "Resolve: THEIRS" })

-- ============================================================================
-- HELP MENU (Full)
-- ============================================================================

vim.keymap.set("n", "<leader>?", function()
    print([[
    GENERAL:  w save | q quit | Q toggle-qf | L lazy | cc/cr config | sw strip | st tab | cd root
    FIND:     ff files | fg grep | fb buffers | fr recent | fm marks | fs symbols (Telescope)
    EXPLORER: e/- toggle sidebar/parent (Netrw) | q close
    GIT:      gs status | gd diff | ga add | gu unstage | gr restore | ]c/[c hunk
    LSP/DIAG: gd def | grr ref | K hover | grn rename | gra action | grf format | [e/]e error
    NAV:      Tab/S-Tab buffers | M-hjkl windows (tmux) | <leader><leader> alternate]])
end, { desc = "Show custom help menu" })
