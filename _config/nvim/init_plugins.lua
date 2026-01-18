-- Neovim Config - Plugin-Based & Production Ready
-- Curated, robust, SSH-optimized

-- ============================================================================
-- SETTINGS
-- ============================================================================

vim.g.mapleader = " "
vim.g.maplocalleader = " "

local opt = vim.opt
opt.swapfile, opt.backup, opt.writebackup = false, false, false
opt.updatetime, opt.timeoutlen = 300, 500
opt.number, opt.relativenumber = true, true
opt.cursorline, opt.signcolumn = true, "auto"  -- Only show when there are signs
opt.termguicolors, opt.mouse = true, "a"
opt.scrolloff, opt.sidescrolloff = 8, 8
opt.wrap, opt.showmode = false, false
opt.showcmd, opt.laststatus = true, 3
opt.splitright, opt.splitbelow = true, true
opt.expandtab, opt.shiftwidth, opt.tabstop = true, 4, 4
opt.smartindent = true
opt.ignorecase, opt.smartcase = true, true
opt.incsearch, opt.hlsearch = true, true
opt.completeopt = "menu,menuone,noselect"
opt.hidden, opt.autoread = true, true

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

local map = vim.keymap.set

-- ============================================================================
-- PLUGINS
-- ============================================================================

require("lazy").setup({
  ---------------------------------------------------------------------------
  -- Colorscheme
  ---------------------------------------------------------------------------
  {
    "ellisonleao/gruvbox.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      contrast = "hard",
      italic = {
        strings = false,
        comments = false,
        operators = false,
        folds = false,
      },
    },
    config = function(_, opts)
      require("gruvbox").setup(opts)
      vim.cmd.colorscheme("gruvbox")
    end,
  },

  ---------------------------------------------------------------------------
  -- Mason for LSP server installation (LSP config is native below plugins)
  ---------------------------------------------------------------------------
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
    opts = { ensure_installed = {
        "lua_ls",
        "pyright",
        "rust_analyzer",
        "clangd",
        "bashls",
        "jsonls",
        "yamlls"
      } },
  },

  ---------------------------------------------------------------------------
  -- Completion (blink.cmp) - fast, batteries-included
  -- Default keymaps:
  --   <C-space>    Show completion / toggle docs
  --   <C-e>        Hide completion
  --   <C-y>        Accept completion
  --   <C-p>/<C-n>  Select prev/next (or <Up>/<Down>)
  --   <C-b>/<C-f>  Scroll docs up/down
  --   <Tab>/<S-Tab> Snippet jump forward/backward
  --   <C-k>        Toggle signature help
  -- Custom:
  --   <F2>         Toggle auto-trigger (default: off)
  ---------------------------------------------------------------------------
  {
    "saghen/blink.cmp",
    version = "1.*",
    event = "InsertEnter",
    opts = function()
      -- Auto-trigger state (default: disabled, toggle with F2)
      vim.g.blink_cmp_auto_trigger = false

      vim.keymap.set("n", "<F2>", function()
        vim.g.blink_cmp_auto_trigger = not vim.g.blink_cmp_auto_trigger
        print("Completion auto-trigger: " .. (vim.g.blink_cmp_auto_trigger and "ON" or "OFF"))
      end, { desc = "Toggle completion auto-trigger" })

      return {
        -- Explicitly using defaults for documentation
        keymap = {
          preset = "default",
          ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
          ["<C-e>"] = { "hide", "fallback" },
          ["<C-y>"] = { "select_and_accept", "fallback" },
          ["<Up>"] = { "select_prev", "fallback" },
          ["<Down>"] = { "select_next", "fallback" },
          ["<C-p>"] = { "select_prev", "fallback_to_mappings" },
          ["<C-n>"] = { "select_next", "fallback_to_mappings" },
          ["<C-b>"] = { "scroll_documentation_up", "fallback" },
          ["<C-f>"] = { "scroll_documentation_down", "fallback" },
          ["<Tab>"] = { "snippet_forward", "fallback" },
          ["<S-Tab>"] = { "snippet_backward", "fallback" },
          ["<C-k>"] = { "show_signature", "hide_signature", "fallback" },
        },
        completion = {
          documentation = { auto_show = true },
          trigger = {
            show_on_keyword = function()
              return vim.g.blink_cmp_auto_trigger
            end,
            show_on_trigger_character = function()
              return vim.g.blink_cmp_auto_trigger
            end,
          },
        },
        sources = {
          default = { "lsp", "path", "buffer" },
        },
      }
    end,
  },

  ---------------------------------------------------------------------------
  -- Telescope – fuzzy finder
  -- Default keymaps (in picker):
  --   <C-n>/<C-p>    Select next/prev item (or <Down>/<Up>)
  --   <CR>           Confirm selection
  --   <C-x>          Open in horizontal split
  --   <C-v>          Open in vertical split
  --   <C-t>          Open in new tab
  --   <C-u>/<C-d>    Scroll preview up/down
  --   <C-/>          Show mappings help (insert mode)
  --   ?              Show mappings help (normal mode)
  --   <Esc>/<C-c>    Close picker
  ---------------------------------------------------------------------------
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    version = false,
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

  -- Git Commands
  {
    "tpope/vim-fugitive",
    cmd = { "Git", "G" },
    keys = {
      { "<leader>gs", "<cmd>Git<cr>", desc = "Git status" },
      { "<leader>gc", "<cmd>Git commit<cr>", desc = "Git commit" },
      { "<leader>gp", "<cmd>Git push<cr>", desc = "Git push" },
      { "<leader>gl", "<cmd>Git log<cr>", desc = "Git log" },
    },
  },

  -- Git Signs (gutter indicators)
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      signs = {
        add = { text = "+" },
        change = { text = "~" },
        delete = { text = "_" },
        topdelete = { text = "‾" },
        changedelete = { text = "~" },
      },
      on_attach = function(bufnr)
        local gs = package.loaded.gitsigns
        local function m(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
        end
        -- Navigation
        m("n", "]c", function()
          if vim.wo.diff then return "]c" end
          vim.schedule(function() gs.next_hunk() end)
          return "<Ignore>"
        end, "Next hunk")
        m("n", "[c", function()
          if vim.wo.diff then return "[c" end
          vim.schedule(function() gs.prev_hunk() end)
          return "<Ignore>"
        end, "Prev hunk")
        -- Actions (matching init_minimal.lua)
        m("n", "<leader>ga", gs.stage_hunk, "Stage hunk")
        m("n", "<leader>gA", gs.stage_buffer, "Stage buffer")
        m("n", "<leader>gu", gs.undo_stage_hunk, "Undo stage hunk")
        m("n", "<leader>gr", gs.reset_hunk, "Reset hunk")
        m("n", "<leader>gR", gs.reset_buffer, "Reset buffer")
        m("n", "<leader>gp", gs.preview_hunk, "Preview hunk")
        m("n", "<leader>gb", function() gs.blame_line({ full = true }) end, "Blame line")
        m("n", "<leader>gB", gs.toggle_current_line_blame, "Toggle line blame")
        -- Visual mode
        m("v", "<leader>ga", function() gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, "Stage selection")
        m("v", "<leader>gr", function() gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, "Reset selection")
      end,
    },
  },

  -- Git Diff View
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory" },
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>gdo", "<cmd>DiffviewOpen<cr>", desc = "Diff open" },
      { "<leader>gdc", "<cmd>DiffviewClose<cr>", desc = "Diff close" },
      { "<leader>gdf", "<cmd>DiffviewFileHistory %<cr>", desc = "File history" },
      { "<leader>gdh", "<cmd>DiffviewFileHistory<cr>", desc = "Branch history" },
    },
    opts = {
      enhanced_diff_hl = true,
      view = {
        default = { layout = "diff2_horizontal" },
        file_history = { layout = "diff2_horizontal" },
      },
      file_panel = {
        listing_style = "list",
        win_config = {
          position = "left",
          width = 35,
        },
      },
      hooks = {
        diff_buf_read = function()
          vim.opt_local.wrap = false
          vim.opt_local.list = false
          vim.opt_local.relativenumber = false
        end,
      },
    },
  },

  ---------------------------------------------------------------------------
  -- Auto pairs – extra, but unobtrusive
  ---------------------------------------------------------------------------
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {},
  },

  ---------------------------------------------------------------------------
  -- Statusline – functional equivalent to simple statusline in minimal config
  ---------------------------------------------------------------------------
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = {
      options = {
        theme = "gruvbox",
        globalstatus = true,
        component_separators = { left = "|", right = "|" },
        section_separators = { left = "", right = "" },
        icons_enabled = true,
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = {
          { "branch", icon = "br:" },
          { "diff", symbols = { added = "+", modified = "~", removed = "-" } },
          { "diagnostics", symbols = { error = "E:", warn = "W:", info = "I:", hint = "H:" } },
        },
        lualine_c = { { "filename", path = 1 } },
        lualine_x = { "encoding", "fileformat", "filetype" },
        lualine_y = { "progress" },
        lualine_z = { "location" },
      },
    },
  },

  ---------------------------------------------------------------------------
  -- File explorer (nvim-tree)
  ---------------------------------------------------------------------------
  {
    "nvim-tree/nvim-tree.lua",
    cmd = { "NvimTreeToggle", "NvimTreeFocus" },
    keys = {
      { "<leader>e", "<cmd>NvimTreeToggle<cr>", desc = "Explorer sidebar" },
      { "-", "<cmd>NvimTreeToggle<cr>", desc = "Explorer sidebar" },
    },
    opts = {
      view = { width = 30 },
      renderer = { group_empty = true },
      filters = { dotfiles = false },
      on_attach = function(bufnr)
        local api = require("nvim-tree.api")
        -- Apply all default mappings first
        api.config.mappings.default_on_attach(bufnr)
        -- Default mappings include: (explicitly listed for documentation)
        -- <CR>/o = open, <C-v> = vsplit, <C-x> = split, <C-t> = tabnew
        -- <Tab> = preview, R = refresh, a = create, d = delete, r = rename
        -- x = cut, c = copy, p = paste, y = copy_name, Y = copy_path
        -- gy = copy_absolute_path, H = toggle_dotfiles, I = toggle_git_ignored
        -- q = close, ? = toggle_help
        -- Additional close mapping
        vim.keymap.set("n", "<Esc>", api.tree.close, { buffer = bufnr, desc = "Close" })
      end,
    },
  },

  ---------------------------------------------------------------------------
  -- Which-key – helper for discovering mappings
  ---------------------------------------------------------------------------
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    init = function()
      vim.o.timeout = true
      vim.o.timeoutlen = 300
    end,
    opts = {},
  },

  ---------------------------------------------------------------------------
  -- Indent guides – purely visual
  ---------------------------------------------------------------------------
  {
    "lukas-reineke/indent-blankline.nvim",
    event = { "BufReadPost", "BufNewFile" },
    main = "ibl",
    opts = {
      indent = { char = "│" },
      scope = { enabled = false },
    },
  },
}, {
  rocks = { enabled = false },
  checker = { enabled = true },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip", "tarPlugin", "tohtml", "tutor", "zipPlugin",
      },
    },
  },
})

-- ============================================================================
-- NATIVE LSP (Neovim 0.11+)
-- ============================================================================

-- Add Mason bin to PATH so vim.lsp.enable() can find servers
vim.env.PATH = vim.fn.stdpath("data") .. "/mason/bin:" .. vim.env.PATH

-- Default config for all servers (blink.cmp capabilities)
vim.lsp.config("*", {
  capabilities = require("blink.cmp").get_lsp_capabilities(),
})

-- Server-specific settings
vim.lsp.config("lua_ls", {
  settings = { Lua = { workspace = { checkThirdParty = false }, diagnostics = { globals = { "vim" } } } },
})
vim.lsp.config("yamlls", {
  settings = { yaml = { keyOrdering = false } },
})

-- Enable servers
vim.lsp.enable({ "lua_ls", "pyright", "rust_analyzer", "clangd", "bashls", "jsonls", "yamlls" })

-- Diagnostics
vim.diagnostic.config({
  virtual_text = { prefix = "●", spacing = 2 },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "✘",
      [vim.diagnostic.severity.WARN] = "▲",
      [vim.diagnostic.severity.HINT] = "⚑",
      [vim.diagnostic.severity.INFO] = "»",
    },
  },
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  float = { border = "rounded", source = true },
})

-- LSP keymaps on attach (using Neovim 0.11+ default keys)
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    local m = function(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = ev.buf, silent = true, desc = desc })
    end
    m("n", "gd", vim.lsp.buf.definition, "Definition")
    m("n", "gD", vim.lsp.buf.declaration, "Declaration")
    m("n", "grr", vim.lsp.buf.references, "References")
    m("n", "gri", vim.lsp.buf.implementation, "Implementation")
    m("n", "gry", vim.lsp.buf.type_definition, "Type definition")
    m("n", "K", vim.lsp.buf.hover, "Hover")
    m("n", "grn", vim.lsp.buf.rename, "Rename")
    m("n", "gra", vim.lsp.buf.code_action, "Code action")
    m("i", "<C-s>", vim.lsp.buf.signature_help, "Signature help")
    m("n", "grf", function() vim.lsp.buf.format({ async = true }) end, "Format")
  end,
})

-- ============================================================================
-- UTILITIES
-- ============================================================================

local function strip_whitespace()
  local view = vim.fn.winsaveview()
  vim.cmd([[%s/\s\+$//e]])
  vim.fn.winrestview(view)
  print("Stripped trailing whitespace")
end

local function set_tab(width)
  local num = width or tonumber(vim.fn.input("Set tabstop = softtabstop = shiftwidth = "))
  if num and num > 0 then
    vim.bo.tabstop = num
    vim.bo.softtabstop = num
    vim.bo.shiftwidth = num
    print(string.format("tabstop=%d shiftwidth=%d softtabstop=%d %s",
      vim.bo.tabstop, vim.bo.shiftwidth, vim.bo.softtabstop,
      vim.bo.expandtab and "expandtab" or "noexpandtab"))
  end
end

local function close_hidden_buffers()
  local visible = {}
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    visible[vim.api.nvim_win_get_buf(win)] = true
  end

  local closed = 0
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and not visible[buf] and vim.bo[buf].buftype == "" then
      pcall(vim.api.nvim_buf_delete, buf, {})
      closed = closed + 1
    end
  end
  print("Closed " .. closed .. " hidden buffers")
end

local function toggle_number()
  if vim.wo.number and vim.wo.relativenumber then
    vim.wo.relativenumber = false
    print("Numbers: absolute")
  elseif vim.wo.number and not vim.wo.relativenumber then
    vim.wo.number = false
    print("Numbers: off")
  else
    vim.wo.number = true
    vim.wo.relativenumber = true
    print("Numbers: hybrid")
  end
end

-- ============================================================================
-- KEYMAPS (kept identical to init_minimal.lua where possible)
-- ============================================================================

-- General
map("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear highlight" })
map("n", "<leader>w", "<cmd>w<cr>", { desc = "Save" })
map("n", "<leader>x", "<cmd>q<cr>", { desc = "Quit" })
map("n", "<leader>Q", "<cmd>qa<cr>", { desc = "Quit all" })

-- Diagnostics (using defaults)
map("n", "<C-W>d", vim.diagnostic.open_float, { desc = "Show diagnostic" })
map("n", "[d", vim.diagnostic.goto_prev, { desc = "Prev diagnostic" })
map("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
map("n", "[e", function() vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.ERROR }) end, { desc = "Prev error" })
map("n", "]e", function() vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.ERROR }) end, { desc = "Next error" })
-- map("n", "<leader>d", vim.diagnostic.open_float, { desc = "Show diagnostic" })

-- Windows
map("n", "<C-h>", "<C-w>h", { desc = "Left" })
map("n", "<C-j>", "<C-w>j", { desc = "Down" })
map("n", "<C-k>", "<C-w>k", { desc = "Up" })
map("n", "<C-l>", "<C-w>l", { desc = "Right" })
map("n", "<leader>-", "<cmd>split<cr>", { desc = "Split horizontal" })
map("n", "<leader>|", "<cmd>vsplit<cr>", { desc = "Split vertical" })

-- Buffers
map("n", "<Tab>", "<cmd>bnext<cr>", { desc = "Next buffer" })
map("n", "<S-Tab>", "<cmd>bprevious<cr>", { desc = "Prev buffer" })
map("n", "<leader>bd", "<cmd>bdelete<cr>", { desc = "Delete buffer" })
map("n", "<leader>bl", "<cmd>buffers<cr>", { desc = "List buffers" })

-- Terminal
map("n", "<leader>t", "<cmd>terminal<cr>", { desc = "Terminal" })
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal" })

-- Clipboard
map({ "n", "v" }, "<leader>y", '"+y', { desc = "Yank to clipboard" })
map("n", "<leader>Y", '"+Y', { desc = "Yank line to clipboard" })
map({ "n", "v" }, "<leader>p", '"+p', { desc = "Paste from clipboard" })

-- Indent in visual mode (sticky)
map("v", "<", "<gv")
map("v", ">", ">gv")

-- Move lines
map("n", "<A-j>", "<cmd>m .+1<cr>==", { desc = "Move down" })
map("n", "<A-k>", "<cmd>m .-2<cr>==", { desc = "Move up" })
map("v", "<A-j>", ":m '>+1<cr>gv=gv", { desc = "Move down" })
map("v", "<A-k>", ":m '<-2<cr>gv=gv", { desc = "Move up" })

-- Quickfix/location
map("n", "[q", "<cmd>cprev<cr>", { desc = "Prev quickfix" })
map("n", "]q", "<cmd>cnext<cr>", { desc = "Next quickfix" })
map("n", "<leader>qo", "<cmd>copen<cr>", { desc = "Open quickfix" })
map("n", "<leader>qc", "<cmd>cclose<cr>", { desc = "Close quickfix" })
map("n", "[l", "<cmd>lprev<cr>", { desc = "Prev location" })
map("n", "]l", "<cmd>lnext<cr>", { desc = "Next location" })

-- Toggle number modes
map("n", "<F3>", toggle_number, { desc = "Cycle number modes" })

-- Utility mappings (same as minimal)
map("n", "<leader>sw", strip_whitespace, { desc = "Strip whitespace" })
map("n", "<leader>st", function() set_tab() end, { desc = "Set tab width" })
map("n", "<leader>bo", close_hidden_buffers, { desc = "Close hidden buffers" })

-- Commands for utilities
vim.api.nvim_create_user_command("StripWhitespace", strip_whitespace, { desc = "Strip trailing whitespace" })
vim.api.nvim_create_user_command("SetTab", function(opts)
  set_tab(opts.args ~= "" and tonumber(opts.args) or nil)
end, { nargs = "?", desc = "Set tab width" })
vim.api.nvim_create_user_command("CloseHiddenBuffers", close_hidden_buffers, { desc = "Close hidden buffers" })
vim.api.nvim_create_user_command("ToggleNumber", toggle_number, { desc = "Cycle number modes" })

-- Edit this config file
map("n", "<leader>c", function()
  vim.cmd.edit(vim.fn.stdpath("config") .. "/init_plugins.lua")
end, { desc = "Edit config" })

-- Alternate file
map("n", "<leader><leader>", "<C-^>", { desc = "Alternate file" })

-- Run current file (same semantics as minimal)
map("n", "<leader>r", function()
  local ft = vim.bo.filetype
  local file = vim.fn.shellescape(vim.fn.expand("%:p"))
  local cmds = {
    python = "python3 " .. file,
    sh = "bash " .. file,
    bash = "bash " .. file,
    rust = "cargo run",
    c = "gcc " .. file .. " -o /tmp/a.out && /tmp/a.out",
  }
  if cmds[ft] then
    vim.cmd("terminal " .. cmds[ft])
  else
    print("No run command for: " .. ft)
  end
end, { desc = "Run file" })

-- Lazy
map("n", "<leader>L", "<cmd>Lazy<cr>", { desc = "Lazy" })

-- Simple LSP info popup
map("n", "<leader>li", function()
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  if #clients == 0 then
    print("No LSP clients attached to current buffer")
    return
  end

  local info = { "LSP Clients attached to buffer:" }
  for _, client in ipairs(clients) do
    table.insert(info, string.format("  - %s (id: %d)", client.name, client.id))
  end
  table.insert(info, "")
  table.insert(info, "Log: " .. vim.lsp.get_log_path())

  vim.notify(table.concat(info, "\n"), vim.log.levels.INFO)
end, { desc = "LSP info" })

-- Simple keymap helper window (shorter than minimal, same binding)
map("n", "<leader>?", function()
  local help = {
    "═══════════════════════════════════════════════════════════",
    "                    CUSTOM KEYMAPS (plugins)",
    "═══════════════════════════════════════════════════════════",
    "",
    "GENERAL",
    "  <leader>w      Save",
    "  <leader>x      Quit",
    "  <leader>Q      Quit all",
    "  <Esc>          Clear search highlight",
    "  <leader>c      Edit config",
    "  <leader>?      Show this help",
    "",
    "LSP (gr prefix for actions)",
    "  gd / gD        Definition / Declaration",
    "  grr            References",
    "  gri            Implementation",
    "  gry            Type definition",
    "  K              Hover",
    "  grn            Rename",
    "  gra            Code action",
    "  grf            Format",
    "  <C-s>          Signature help (insert)",
    "  <leader>li     LSP info",
    "",
    "DIAGNOSTICS",
    "  [d / ]d        Prev/Next diagnostic",
    "  <C-W>d         Show diagnostic float",
    "",
    "GIT               (gitsigns + native)",
    "  [c / ]c        Prev/Next hunk",
    "  <leader>ga     Stage hunk (visual: selection)",
    "  <leader>gA     Stage buffer",
    "  <leader>gu     Undo stage hunk",
    "  <leader>gr     Reset hunk (visual: selection)",
    "  <leader>gR     Reset buffer",
    "  <leader>gp     Preview hunk",
    "  <leader>gb     Blame line",
    "  <leader>gB     Toggle line blame",
    "  <leader>gd     Diff file (side-by-side)",
    "  <leader>gD     Diff all (full diff)",
    "  <leader>gs     Git status (fugitive)",
    "  <leader>gc     Git commit",
    "  <leader>gl     Git log",
    "  Signs: + (add), ~ (change), _ (delete)",
    "",
    "TELESCOPE (<C-n>/<C-p> select, <C-u>/<C-d> scroll)",
    "  <leader>ff     Find files",
    "  <leader>fg     Search in files",
    "  <leader>fb     Buffers",
    "  <leader>fr     Recent files",
    "  <leader>fm     Marks list",
    "  <leader>fs     LSP symbols",
    "",
    "NAVIGATION",
    "  <leader>e / -  Explorer (nvim-tree)",
    "  <leader><leader> Alternate file",
    "  gf             Go to file (default)",
    "",
    "EDITING",
    "  <leader>sw     Strip whitespace",
    "  <leader>st     Set tab width",
    "  <A-j/k>        Move line(s) down/up",
    "  </>            Indent (visual, sticky)",
    "",
    "CLIPBOARD",
    "  <leader>y/Y/p  Yank/paste using system clipboard",
    "",
    "BUFFERS & WINDOWS",
    "  <Tab>/<S-Tab>  Next/Prev buffer",
    "  <leader>bd     Delete buffer",
    "  <leader>bl     List buffer",
    "  <C-h/j/k/l>    Window navigation",
    "  <leader>-/|    Split windows",
    "",
    "QUICKFIX",
    "  [q / ]q        Prev/Next quickfix",
    "  <leader>qo     Open quickfix",
    "  <leader>qc     Close quickfix",
    "  [l / ]l        Prev/Next location",
    "",
    "COMPLETION (blink.cmp defaults)",
    "  <C-space>      Show / toggle docs",
    "  <C-y>          Accept",
    "  <C-e>          Hide",
    "  <C-n>/<C-p>    Select next/prev",
    "  <C-b>/<C-f>    Scroll docs",
    "  <Tab>/<S-Tab>  Snippet jump",
    "  <C-k>          Signature help",
    "",
    "MISC",
    "  <leader>t      Terminal",
    "  <Esc><Esc>     Exit terminal mode",
    "  <leader>r      Run file",
    "  <F2>           Toggle completion auto-trigger",
    "  <F3>           Cycle number modes",
    "",
    "═══════════════════════════════════════════════════════════",
    "  Press 'q' to close",
    "═══════════════════════════════════════════════════════════",
  }

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, help)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"

  local width = 70
  local height = #help
  local row = math.floor((vim.o.lines - height) / 2) - 1
  local col = math.floor((vim.o.columns - width) / 2)

  vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
  })

  vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, silent = true })
  vim.keymap.set("n", "<Esc>", "<cmd>close<cr>", { buffer = buf, silent = true })
end, { desc = "Show keymaps" })

-- ============================================================================
-- AUTOCOMMANDS (aligned with init_minimal.lua)
-- ============================================================================

local autocmd = vim.api.nvim_create_autocmd

-- Highlight on yank
autocmd("TextYankPost", {
  callback = function()
    vim.highlight.on_yank({ higroup = "IncSearch", timeout = 200 })
  end,
})

-- Restore cursor position
autocmd("BufReadPost", {
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(0) then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Quickfix: q closes qf + loc list
autocmd("FileType", {
  pattern = "qf",
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>cclose<cr><cmd>lclose<cr>", { buffer = event.buf, silent = true })
  end,
})

-- YAML commentstring
autocmd("FileType", {
  pattern = { "yaml", "yml" },
  callback = function()
    vim.bo.commentstring = "# %s"
  end,
})

-- Wrap and spell in text filetypes (extra)
autocmd("FileType", {
  pattern = { "gitcommit", "markdown" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.spell = true
  end,
})

-- Auto-close terminal buffers when job exits
autocmd("TermClose", {
  callback = function() vim.cmd("bdelete!") end,
})
