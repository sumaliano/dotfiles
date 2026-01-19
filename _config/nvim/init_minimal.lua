-- Minimal Neovim Config (plugin-free)
-- Purist native (Neovim 0.11+) | Offline + SSH-friendly | DevOps-focused

-- ============================================================================
-- SETTINGS
-- ============================================================================

vim.g.mapleader = " "
vim.g.maplocalleader = " "

local opt = vim.opt

-- Fast + safe defaults
opt.swapfile = false
opt.backup = false
opt.writebackup = false
opt.hidden = true
opt.autoread = true

opt.updatetime = 300
opt.timeoutlen = 500

opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.signcolumn = "yes"

-- SSH: avoid mouse, avoid truecolor (often misdetected), keep UI simple.
-- Enable colors when explicitly supported.
opt.mouse = ""
opt.termguicolors = (vim.env.TERM ~= nil and not vim.env.TERM:match("^screen") and not vim.env.TERM:match("^tmux"))

opt.scrolloff = 8
opt.sidescrolloff = 8
opt.wrap = false
opt.showmode = false
opt.showcmd = true
opt.cmdheight = 1
opt.laststatus = 2

opt.splitright = true
opt.splitbelow = true

opt.expandtab = true
opt.shiftwidth = 4
opt.tabstop = 4
opt.smartindent = true

opt.ignorecase = true
opt.smartcase = true
opt.incsearch = true
opt.hlsearch = true

opt.completeopt = "menu,menuone,noselect"
opt.pumheight = 10
opt.shortmess:append("c")

-- Diff UX
opt.diffopt:append("vertical")
opt.diffopt:append("linematch:60")
opt.diffopt:append("algorithm:histogram")

opt.list = true
opt.listchars = { tab = "│ ", trail = "·", extends = "→", precedes = "←", nbsp = "␣" }
opt.fillchars = { eob = " ", fold = " ", foldopen = "v", foldsep = " ", foldclose = ">" }

-- Grep: offline, use rg if available.
if vim.fn.executable("rg") == 1 then
  vim.o.grepprg = "rg --vimgrep --no-heading --smart-case"
  vim.o.grepformat = "%f:%l:%c:%m"
end

-- Completion behavior: also complete on '.' (useful for lua/bash/python)
opt.complete:append({ "." })

-- Keep statusline simple & fast.
vim.o.statusline = " %f %m%r%h%w %= %y %{&ff} %l:%c %p%% "

pcall(vim.cmd, "colorscheme retrobox")

local map = vim.keymap.set

-- ============================================================================
-- LSP & DIAGNOSTICS (Neovim 0.11+ native)
-- ============================================================================

-- Enable servers that are installed on the system.
-- (devops-friendly list; add/remove as needed)
local lsp_servers = { "bashls", "pyright", "clangd", "rust_analyzer", "jdtls" }

-- Neovim will only start servers that exist.
vim.lsp.enable(lsp_servers)

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"
    local o = { buffer = ev.buf }

    map("n", "gd", vim.lsp.buf.definition, o)
    map("n", "gD", vim.lsp.buf.declaration, o)
    map("n", "grr", vim.lsp.buf.references, o)
    map("n", "gri", vim.lsp.buf.implementation, o)
    map("n", "gry", vim.lsp.buf.type_definition, o)
    map("n", "K", vim.lsp.buf.hover, o)
    map("n", "grn", vim.lsp.buf.rename, o)
    map("n", "gra", vim.lsp.buf.code_action, o)
    map("i", "<C-s>", vim.lsp.buf.signature_help, o)
    map("n", "grf", function() vim.lsp.buf.format({ async = true }) end, o)
  end,
})

vim.diagnostic.config({
  virtual_text = { prefix = "●", spacing = 2 },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "E",
      [vim.diagnostic.severity.WARN] = "W",
      [vim.diagnostic.severity.HINT] = "H",
      [vim.diagnostic.severity.INFO] = "I",
    },
  },
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  float = { border = "rounded", source = true },
})

map("n", "<C-w>d", vim.diagnostic.open_float, { desc = "Show diagnostic" })
map("n", "[d", vim.diagnostic.goto_prev, { desc = "Prev diagnostic" })
map("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
map("n", "[e", function() vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.ERROR }) end, { desc = "Prev error" })
map("n", "]e", function() vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.ERROR }) end, { desc = "Next error" })

-- ============================================================================
-- COMPLETION
-- ============================================================================

-- Tab: complete or indent
map("i", "<Tab>", function()
  if vim.fn.pumvisible() == 1 then return "<C-n>" end
  local col = vim.fn.col(".") - 1
  if col == 0 or vim.fn.getline("."):sub(col, col):match("%s") then return "<Tab>" end
  return vim.bo.omnifunc ~= "" and "<C-x><C-o>" or "<C-n>"
end, { expr = true })

map("i", "<S-Tab>", function() return vim.fn.pumvisible() == 1 and "<C-p>" or "<S-Tab>" end, { expr = true })
map("i", "<CR>", function() return vim.fn.pumvisible() == 1 and "<C-y>" or "<CR>" end, { expr = true })

-- Auto-trigger completion while typing (toggle with F2)
local auto_cmp_group = vim.api.nvim_create_augroup("AutoCmp", { clear = true })
local auto_cmp = false

map("n", "<F2>", function()
  auto_cmp = not auto_cmp
  vim.api.nvim_clear_autocmds({ group = auto_cmp_group })

  if auto_cmp then
    vim.api.nvim_create_autocmd("TextChangedI", {
      group = auto_cmp_group,
      callback = function()
        if vim.fn.pumvisible() == 1 then return end
        local col = vim.fn.col(".") - 1
        if col < 2 then return end
        local char = vim.fn.getline("."):sub(col, col)
        if char:match("[%w_%.%-]") then
          local keys = vim.bo.omnifunc ~= "" and "<C-x><C-o>" or "<C-n>"
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), "n", false)
        end
      end,
    })
  end

  print("Auto-completion: " .. (auto_cmp and "ON" or "OFF"))
end, { desc = "Toggle auto-completion" })

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
    print(string.format(
      "tabstop=%d shiftwidth=%d softtabstop=%d %s",
      vim.bo.tabstop,
      vim.bo.shiftwidth,
      vim.bo.softtabstop,
      vim.bo.expandtab and "expandtab" or "noexpandtab"
    ))
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

map("n", "<leader>sw", strip_whitespace, { desc = "Strip whitespace" })
map("n", "<leader>st", function() set_tab() end, { desc = "Set tab width" })
map("n", "<leader>bo", close_hidden_buffers, { desc = "Close hidden buffers" })

vim.api.nvim_create_user_command("StripWhitespace", strip_whitespace, { desc = "Strip trailing whitespace" })
vim.api.nvim_create_user_command("SetTab", function(opts) set_tab(opts.args ~= "" and tonumber(opts.args) or nil) end, {
  nargs = "?",
  desc = "Set tab width",
})
vim.api.nvim_create_user_command("CloseHiddenBuffers", close_hidden_buffers, { desc = "Close all hidden buffers" })
vim.api.nvim_create_user_command("ToggleNumber", toggle_number, { desc = "Cycle number modes" })

-- ============================================================================
-- NAVIGATION (offline, no plugins)
-- ============================================================================

vim.g.netrw_banner = 0
vim.g.netrw_liststyle = 3
vim.g.netrw_winsize = 25

-- Find files using fd or find.
map("n", "<leader>ff", function()
  local cmd = (vim.fn.executable("fd") == 1)
      and "fd --type f --hidden --exclude .git"
      or "find . -type f ! -path '*/.git/*' 2>/dev/null"

  local files = vim.fn.systemlist(cmd)
  if #files == 0 then return print("No files found") end

  if #files > 1000 then
    files = vim.list_slice(files, 1, 1000)
    print("Showing first 1000 files")
  end

  vim.ui.select(files, {
    prompt = "Find file:",
    format_item = function(item) return item:gsub("^%./", "") end,
  }, function(choice)
    if choice then vim.cmd("edit " .. vim.fn.fnameescape(choice)) end
  end)
end, { desc = "Find files" })

-- Find by pattern
map("n", "<leader>fp", function()
  local pattern = vim.fn.input("Pattern (*.lua, *.py, etc): ")
  if pattern == "" then return end

  local cmd = (vim.fn.executable("fd") == 1)
      and ("fd --type f --hidden --exclude .git --glob " .. vim.fn.shellescape(pattern))
      or ("find . -type f -name " .. vim.fn.shellescape(pattern) .. " ! -path '*/.git/*' 2>/dev/null")

  local files = vim.fn.systemlist(cmd)
  if #files == 0 then return print("No files matching " .. pattern) end

  vim.ui.select(files, {
    prompt = "Select:",
    format_item = function(item) return item:gsub("^%./", "") end,
  }, function(choice)
    if choice then vim.cmd("edit " .. vim.fn.fnameescape(choice)) end
  end)
end, { desc = "Find by pattern" })

-- Grep via :grep (rg if configured)
map("n", "<leader>fg", function()
  local search = vim.fn.input("Search: ")
  if search == "" then return end

  vim.cmd("silent! grep! " .. vim.fn.shellescape(search))
  local qf_size = #vim.fn.getqflist()
  if qf_size > 0 then
    vim.cmd("copen")
    print(qf_size .. " matches")
  else
    print("No matches found")
  end
end, { desc = "Search in files" })

map("n", "<leader>fw", function()
  local word = vim.fn.expand("<cword>")
  vim.cmd("silent! grep! " .. vim.fn.shellescape(word))
  local qf_size = #vim.fn.getqflist()
  if qf_size > 0 then
    vim.cmd("copen")
    print(qf_size .. " matches for '" .. word .. "'")
  else
    print("No matches")
  end
end, { desc = "Search word" })

-- Buffers list via ui.select
map("n", "<leader>fb", function()
  local buffers = vim.tbl_filter(function(buf)
    return vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buflisted
  end, vim.api.nvim_list_bufs())

  if #buffers == 0 then return print("No buffers") end

  local items = vim.tbl_map(function(buf)
    local name = vim.api.nvim_buf_get_name(buf)
    local display = (name ~= "" and vim.fn.fnamemodify(name, ":~:.") or "[No Name]")
    local modified = vim.bo[buf].modified and " [+]" or ""
    local current = (buf == vim.api.nvim_get_current_buf()) and " %" or ""
    return { buf = buf, display = display .. modified .. current }
  end, buffers)

  vim.ui.select(items, {
    prompt = "Buffer:",
    format_item = function(item) return item.display end,
  }, function(choice)
    if choice then vim.api.nvim_set_current_buf(choice.buf) end
  end)
end, { desc = "List buffers" })

-- Recent files
map("n", "<leader>fr", function()
  local recent = vim.tbl_filter(function(file)
    return vim.fn.filereadable(file) == 1
  end, vim.v.oldfiles)

  if #recent == 0 then return print("No recent files") end
  recent = vim.list_slice(recent, 1, math.min(50, #recent))

  vim.ui.select(recent, {
    prompt = "Recent:",
    format_item = function(item) return vim.fn.fnamemodify(item, ":~:.") end,
  }, function(choice)
    if choice then vim.cmd("edit " .. vim.fn.fnameescape(choice)) end
  end)
end, { desc = "Recent files" })

-- netrw
map("n", "<leader>e", "<cmd>Lexplore<cr>", { desc = "Explorer sidebar" })

-- Browse current directory in a tab (keeps session clean over SSH)
map("n", "-", function()
  local dir = vim.fn.expand("%:p:h")
  if dir == "" then dir = vim.fn.getcwd() end

  vim.cmd("tabnew")
  vim.cmd("Explore " .. vim.fn.fnameescape(dir))

  vim.defer_fn(function()
    vim.keymap.set("n", "<Esc>", "<cmd>tabclose<cr>", { buffer = true, silent = true })
    vim.keymap.set("n", "q", "<cmd>tabclose<cr>", { buffer = true, silent = true })
  end, 50)
end, { desc = "Browse directory" })

vim.api.nvim_create_autocmd("FileType", {
  pattern = "netrw",
  callback = function()
    vim.keymap.set("n", "<Esc>", "<cmd>Lexplore<cr>", { buffer = true, silent = true })
    vim.keymap.set("n", "q", "<cmd>Lexplore<cr>", { buffer = true, silent = true })
  end,
})

map("n", "<leader><leader>", "<C-^>", { desc = "Alternate file" })

-- Marks list
map("n", "<leader>fm", function()
  local marks = vim.fn.getmarklist()
  local items = {}

  for _, mark in ipairs(marks) do
    if mark.mark:match("^'[a-zA-Z]$") then
      local buf = (vim.api.nvim_buf_is_loaded(mark.pos[1]) and mark.pos[1]) or nil
      if buf then
        local file = vim.api.nvim_buf_get_name(buf)
        local line = mark.pos[2]
        table.insert(items, {
          mark = mark.mark:sub(2),
          display = mark.mark:sub(2)
              .. " → "
              .. ((file ~= "" and vim.fn.fnamemodify(file, ":~:.") or "[No Name]"))
              .. ":"
              .. line,
        })
      end
    end
  end

  if #items == 0 then return print("No marks") end

  vim.ui.select(items, {
    prompt = "Mark:",
    format_item = function(item) return item.display end,
  }, function(choice)
    if choice then vim.cmd("normal! '" .. choice.mark) end
  end)
end, { desc = "List marks" })

-- ============================================================================
-- GIT (simple, native + fast)
-- ============================================================================

-- Git features: still on-demand (no background timers), but with better
-- "what changed" visibility via quick hunk navigation + preview.
if vim.fn.executable("git") == 1 then
  vim.fn.sign_define("GitAdd", { text = "+", texthl = "DiffAdd" })
  vim.fn.sign_define("GitChange", { text = "~", texthl = "DiffChange" })
  vim.fn.sign_define("GitDelete", { text = "_", texthl = "DiffDelete" })
  vim.fn.sign_define("GitTopDelete", { text = "‾", texthl = "DiffDelete" })

  local function buf_abs_path()
    local p = vim.api.nvim_buf_get_name(0)
    return (p ~= "") and p or nil
  end

  local function git_tracked_relpath(abs)
    local rel = vim.fn.systemlist("git ls-files --full-name " .. vim.fn.shellescape(abs))[1]
    if vim.v.shell_error ~= 0 or not rel or rel == "" then return nil end
    return rel
  end

  local function scratch(lines, name, ft)
    vim.cmd("tabnew")
    vim.bo.buftype = "nofile"
    vim.bo.bufhidden = "wipe"
    vim.bo.swapfile = false
    if name then vim.api.nvim_buf_set_name(0, name) end
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
    if ft then vim.bo.filetype = ft end
    vim.bo.modifiable = false
    vim.keymap.set("n", "q", "<cmd>bd<cr>", { buffer = true, silent = true })
  end

  -- ---------------------------------
  -- Minimal git signs (gitsigns-like)
  --   - no background polling
  --   - update on BufRead/BufWrite/CursorHold (debounced)
  -- ---------------------------------

  local git_tracked = {} -- bufnr -> bool
  local update_timers = {} -- bufnr -> uv_timer

  local function is_normal_file(bufnr)
    return vim.api.nvim_buf_is_valid(bufnr)
      and vim.bo[bufnr].buftype == ""
      and vim.api.nvim_buf_get_name(bufnr) ~= ""
  end

  local function unplace_signs(bufnr)
    pcall(vim.fn.sign_unplace, "git_signs", { buffer = bufnr })
  end

  -- Place signs from `git diff -U0` for a file
  local function place_signs(bufnr)
    if not is_normal_file(bufnr) then return end

    local abs = vim.api.nvim_buf_get_name(bufnr)

    -- tracked cache
    if git_tracked[bufnr] == nil then
      vim.fn.system({ "git", "ls-files", "--error-unmatch", abs })
      git_tracked[bufnr] = (vim.v.shell_error == 0)
    end

    if not git_tracked[bufnr] then
      unplace_signs(bufnr)
      return
    end

    local out = vim.fn.systemlist({ "git", "diff", "--no-color", "--no-ext-diff", "-U0", "--", abs })
    if vim.v.shell_error ~= 0 then return end

    unplace_signs(bufnr)
    if #out == 0 then return end

    local i = 1
    while i <= #out do
      local l = out[i]
      local os, oc, ns, nc = l:match("^@@%s*%-(%d+),?(%d*)%s*%+(%d+),?(%d*)%s*@@")
      if ns then
        oc = (oc ~= "" and tonumber(oc)) or 1
        nc = (nc ~= "" and tonumber(nc)) or 1
        ns = tonumber(ns)

        local has_add, has_del = false, false
        local cur_new = ns

        i = i + 1
        while i <= #out and not out[i]:match("^@@") do
          local dl = out[i]
          if dl:match("^%+") and not dl:match("^%+%+%+") then
            has_add = true
            cur_new = cur_new + 1
          elseif dl:match("^%-") and not dl:match("^%-%-%-") then
            has_del = true
          elseif dl:match("^ ") then
            cur_new = cur_new + 1
          end
          i = i + 1
        end

        local hunk_type
        if has_add and has_del then
          hunk_type = "change"
        elseif has_add then
          hunk_type = "add"
        else
          hunk_type = "delete"
        end

        if hunk_type == "delete" then
          local sign_line = (ns > 0) and ns or 1
          local sign_name = (ns == 0) and "GitTopDelete" or "GitDelete"
          vim.fn.sign_place(0, "git_signs", sign_name, bufnr, { lnum = sign_line, priority = 5 })
        else
          local start_line = ns
          local end_line = (nc == 0) and ns or (ns + nc - 1)
          local sign_name = (hunk_type == "change") and "GitChange" or "GitAdd"
          for lnum = start_line, end_line do
            if lnum > 0 then
              vim.fn.sign_place(0, "git_signs", sign_name, bufnr, { lnum = lnum, priority = 5 })
            end
          end
        end
      else
        i = i + 1
      end
    end
  end

  local function schedule_place_signs(bufnr)
    if not is_normal_file(bufnr) then return end

    local t = update_timers[bufnr]
    if t then
      pcall(t.stop, t)
      pcall(t.close, t)
    end

    t = vim.uv.new_timer()
    update_timers[bufnr] = t

    t:start(200, 0, vim.schedule_wrap(function()
      if update_timers[bufnr] == t then
        update_timers[bufnr] = nil
      end
      pcall(t.stop, t)
      pcall(t.close, t)
      place_signs(bufnr)
    end))
  end

  -- update signs on common events
  vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
    callback = function(ev) schedule_place_signs(ev.buf) end,
  })

  vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
    callback = function()
      schedule_place_signs(vim.api.nvim_get_current_buf())
    end,
  })

  vim.api.nvim_create_autocmd("BufDelete", {
    callback = function(ev)
      unplace_signs(ev.buf)
      git_tracked[ev.buf] = nil
      local t = update_timers[ev.buf]
      if t then
        pcall(t.stop, t)
        pcall(t.close, t)
        update_timers[ev.buf] = nil
      end
    end,
  })

  -- ---------------------------------
  -- Hunks: parse with full diff content for staging
  -- ---------------------------------

  local function get_hunks_for_file(abs, staged)
    local cmd = staged
      and "git diff --cached --no-color --no-ext-diff -U0 -- " .. vim.fn.shellescape(abs)
      or "git diff --no-color --no-ext-diff -U0 -- " .. vim.fn.shellescape(abs)
    local out = vim.fn.systemlist(cmd)
    if vim.v.shell_error ~= 0 or #out == 0 then return {} end

    local hunks = {}
    local i = 1
    while i <= #out do
      local l = out[i]
      local old_start, old_count, new_start, new_count = l:match("^@@%s*%-(%d+),?(%d*)%s*%+(%d+),?(%d*)%s*@@")
      if new_start then
        old_start = tonumber(old_start)
        old_count = (old_count ~= "" and tonumber(old_count)) or 1
        new_start = tonumber(new_start)
        new_count = (new_count ~= "" and tonumber(new_count)) or 1

        local diff_lines = { l }
        i = i + 1
        while i <= #out and not out[i]:match("^@@") do
          table.insert(diff_lines, out[i])
          i = i + 1
        end

        local start_line = new_start
        local end_line = (new_count == 0) and new_start or (new_start + new_count - 1)

        table.insert(hunks, {
          start_line = start_line,
          end_line = end_line,
          old_start = old_start,
          old_count = old_count,
          new_start = new_start,
          new_count = new_count,
          header = l,
          diff_lines = diff_lines,
        })
      else
        i = i + 1
      end
    end
    return hunks
  end

  local function hunk_at_cursor(hunks)
    local line = vim.api.nvim_win_get_cursor(0)[1]
    for _, h in ipairs(hunks) do
      if line >= h.start_line and line <= h.end_line then return h end
      if h.start_line == h.end_line and line == h.start_line then return h end
    end
    return nil
  end

  local function goto_hunk(direction)
    local abs = buf_abs_path()
    if not abs then return print("No file") end
    if not git_tracked_relpath(abs) then return print("File not tracked") end

    local hunks = get_hunks_for_file(abs)
    if #hunks == 0 then return print("No hunks") end

    local cur = vim.api.nvim_win_get_cursor(0)[1]

    if direction == "next" then
      for _, h in ipairs(hunks) do
        if h.start_line > cur then
          vim.api.nvim_win_set_cursor(0, { h.start_line, 0 })
          return
        end
      end
      vim.api.nvim_win_set_cursor(0, { hunks[1].start_line, 0 })
      return
    end

    for i = #hunks, 1, -1 do
      if hunks[i].start_line < cur then
        vim.api.nvim_win_set_cursor(0, { hunks[i].start_line, 0 })
        return
      end
    end
    vim.api.nvim_win_set_cursor(0, { hunks[#hunks].start_line, 0 })
  end

  local function preview_hunk()
    local abs = buf_abs_path()
    if not abs then return print("No file") end
    if not git_tracked_relpath(abs) then return print("File not tracked") end

    local hunks = get_hunks_for_file(abs)
    if #hunks == 0 then return print("No hunks") end

    local h = hunk_at_cursor(hunks)
    if not h then return print("No hunk at cursor") end

    -- Show just this hunk in a floating window
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, h.diff_lines)
    vim.bo[buf].filetype = "diff"
    vim.bo[buf].modifiable = false
    vim.bo[buf].bufhidden = "wipe"

    local width = math.min(80, vim.o.columns - 4)
    local height = math.min(#h.diff_lines, math.floor(vim.o.lines * 0.4))

    vim.api.nvim_open_win(buf, true, {
      relative = "cursor",
      row = 1,
      col = 0,
      width = width,
      height = height,
      style = "minimal",
      border = "rounded",
      title = " Hunk Preview ",
      title_pos = "center",
    })

    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, silent = true })
    vim.keymap.set("n", "<Esc>", "<cmd>close<cr>", { buffer = buf, silent = true })
  end

  -- Generate patch for a hunk (for staging/unstaging)
  local function make_hunk_patch(abs, hunk, reverse)
    local rel = git_tracked_relpath(abs)
    if not rel then return nil end

    local patch = {
      "--- a/" .. rel,
      "+++ b/" .. rel,
    }

    for _, line in ipairs(hunk.diff_lines) do
      if reverse then
        if line:match("^%+") and not line:match("^%+%+%+") then
          table.insert(patch, "-" .. line:sub(2))
        elseif line:match("^%-") and not line:match("^%-%-%-") then
          table.insert(patch, "+" .. line:sub(2))
        elseif line:match("^@@") then
          -- Swap old/new in header
          local os, oc, ns, nc = line:match("^@@%s*%-(%d+),?(%d*)%s*%+(%d+),?(%d*)%s*@@")
          oc = oc ~= "" and oc or "1"
          nc = nc ~= "" and nc or "1"
          table.insert(patch, string.format("@@ -%s,%s +%s,%s @@", ns, nc, os, oc))
        else
          table.insert(patch, line)
        end
      else
        table.insert(patch, line)
      end
    end

    return table.concat(patch, "\n") .. "\n"
  end

  local function stage_hunk()
    local abs = buf_abs_path()
    if not abs then return print("No file") end

    local hunks = get_hunks_for_file(abs)
    if #hunks == 0 then return print("No hunks") end

    local h = hunk_at_cursor(hunks)
    if not h then return print("No hunk at cursor") end

    local patch = make_hunk_patch(abs, h, false)
    if not patch then return print("Failed to generate patch") end

    local result = vim.fn.systemap("git apply --cached --unidiff-zero -", patch)
    if vim.v.shell_error == 0 then
      print("Staged hunk")
      schedule_place_signs(vim.api.nvim_get_current_buf())
    else
      print("Failed to stage: " .. result)
    end
  end

  local function unstage_hunk()
    local abs = buf_abs_path()
    if not abs then return print("No file") end

    -- Get staged hunks
    local hunks = get_hunks_for_file(abs, true)
    if #hunks == 0 then return print("No staged hunks") end

    local h = hunk_at_cursor(hunks)
    if not h then
      -- If cursor not on staged hunk, unstage the last one
      h = hunks[#hunks]
    end

    local patch = make_hunk_patch(abs, h, true)
    if not patch then return print("Failed to generate patch") end

    local result = vim.fn.systemap("git apply --cached --unidiff-zero -", patch)
    if vim.v.shell_error == 0 then
      print("Unstaged hunk")
      schedule_place_signs(vim.api.nvim_get_current_buf())
    else
      print("Failed to unstage: " .. result)
    end
  end

  local function reset_hunk()
    local abs = buf_abs_path()
    if not abs then return print("No file") end

    local hunks = get_hunks_for_file(abs)
    if #hunks == 0 then return print("No hunks") end

    local h = hunk_at_cursor(hunks)
    if not h then return print("No hunk at cursor") end

    local patch = make_hunk_patch(abs, h, true)
    if not patch then return print("Failed to generate patch") end

    local result = vim.fn.systemap("git apply --unidiff-zero -", patch)
    if vim.v.shell_error == 0 then
      print("Reset hunk")
      vim.cmd("edit")
    else
      print("Failed to reset: " .. result)
    end
  end

  -- ---------------------------------
  -- Commands / mappings
  -- ---------------------------------

  map("n", "]c", function() goto_hunk("next") end, { desc = "Next hunk" })
  map("n", "[c", function() goto_hunk("prev") end, { desc = "Prev hunk" })
  map("n", "<leader>hp", preview_hunk, { desc = "Preview hunk" })
  map("n", "<leader>hs", stage_hunk, { desc = "Stage hunk" })
  map("n", "<leader>hu", unstage_hunk, { desc = "Unstage hunk" })
  map("n", "<leader>hr", reset_hunk, { desc = "Reset hunk" })

  map("n", "<leader>gs", "<cmd>!git status<cr>", { desc = "Git status" })
  map("n", "<leader>gC", "<cmd>terminal git commit<cr>", { desc = "Git commit" })
  map("n", "<leader>gP", "<cmd>!git push<cr>", { desc = "Git push" })

  -- Git log
  map("n", "<leader>gl", function()
    local abs = buf_abs_path()
    local cmd = abs and ("git log --oneline -20 -- " .. vim.fn.shellescape(abs)) or "git log --oneline -20"
    local log = vim.fn.systemlist(cmd)
    if #log == 0 then return print("No history") end
    scratch(log, "git log", nil)
  end, { desc = "Git log" })

  -- Diff current file vs HEAD in built-in diff mode
  map("n", "<leader>gd", function()
    local abs = buf_abs_path()
    if not abs then return print("No file") end

    local rel = git_tracked_relpath(abs)
    if not rel then return print("File not tracked") end

    local content = vim.fn.systemlist("git show HEAD:" .. rel)
    if vim.v.shell_error ~= 0 then return print("No HEAD version") end

    local ft = vim.bo.filetype
    local pos = vim.fn.getpos(".")

    vim.cmd("leftabove vnew")
    vim.bo.buftype = "nofile"
    vim.bo.bufhidden = "wipe"
    vim.bo.swapfile = false
    vim.api.nvim_buf_set_name(0, "HEAD:" .. vim.fn.fnamemodify(abs, ":t"))
    vim.api.nvim_buf_set_lines(0, 0, -1, false, content)
    vim.bo.modifiable = false
    vim.bo.filetype = ft
    vim.cmd("diffthis")

    vim.cmd("wincmd p")
    vim.cmd("diffthis")
    vim.fn.setpos(".", pos)

    print("Diff mode: use built-in ]c/[c, :diffoff to exit")
  end, { desc = "Git diff file (vs HEAD)" })

  -- Full repo diff
  map("n", "<leader>gD", function()
    local diff = vim.fn.systemlist("git diff HEAD")
    if #diff == 0 then return print("No changes") end
    scratch(diff, "git diff", "diff")
  end, { desc = "Git diff repo (vs HEAD)" })

  -- Blame (scratch)
  map("n", "<leader>gb", function()
    local abs = buf_abs_path()
    if not abs then return end

    local blame = vim.fn.systemlist("git blame --date=short " .. vim.fn.shellescape(abs))
    if vim.v.shell_error ~= 0 then return print("Blame failed") end

    scratch(blame, "git blame", nil)
  end, { desc = "Git blame" })

  -- Stage/reset helpers
  map("n", "<leader>ga", function()
    local abs = buf_abs_path()
    if not abs then return print("No file") end
    vim.fn.systemap("git add " .. vim.fn.shellescape(abs))
    if vim.v.shell_error == 0 then print("Staged buffer") else print("Failed to stage buffer") end
  end, { desc = "Git stage buffer" })

  map("n", "<leader>gA", function()
    vim.fn.systemap("git add -A")
    if vim.v.shell_error == 0 then print("Staged all changes") else print("Failed to stage changes") end
  end, { desc = "Git stage all" })

  map("n", "<leader>gu", function()
    local abs = buf_abs_path()
    if not abs then return print("No file") end
    vim.fn.systemap("git reset HEAD " .. vim.fn.shellescape(abs))
    if vim.v.shell_error == 0 then print("Unstaged buffer") else print("Failed to unstage buffer") end
  end, { desc = "Git unstage buffer" })

  map("n", "<leader>gR", function()
    local abs = buf_abs_path()
    if not abs then return print("No file") end
    vim.fn.systemap("git checkout -- " .. vim.fn.shellescape(abs))
    if vim.v.shell_error == 0 then
      print("Reset buffer")
      vim.cmd("edit")
    else
      print("Failed to reset buffer")
    end
  end, { desc = "Git reset buffer" })
end

-- ============================================================================
-- KEYMAPS
-- ============================================================================

map("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear highlight" })
map("n", "<leader>w", "<cmd>w<cr>", { desc = "Save" })
map("n", "<leader>x", "<cmd>q<cr>", { desc = "Quit" })
map("n", "<leader>Q", "<cmd>qa<cr>", { desc = "Quit all" })

map("n", "<C-h>", "<C-w>h", { desc = "Left" })
map("n", "<C-j>", "<C-w>j", { desc = "Down" })
map("n", "<C-k>", "<C-w>k", { desc = "Up" })
map("n", "<C-l>", "<C-w>l", { desc = "Right" })
map("n", "<leader>-", "<cmd>split<cr>", { desc = "Split horizontal" })
map("n", "<leader>|", "<cmd>vsplit<cr>", { desc = "Split vertical" })

map("n", "<Tab>", "<cmd>bnext<cr>", { desc = "Next buffer" })
map("n", "<S-Tab>", "<cmd>bprevious<cr>", { desc = "Prev buffer" })
map("n", "<leader>bd", "<cmd>bdelete<cr>", { desc = "Delete buffer" })
map("n", "<leader>bl", "<cmd>buffers<cr>", { desc = "List buffers" })

map("n", "<leader>t", "<cmd>terminal<cr>", { desc = "Terminal" })
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal" })

-- Clipboard maps are useful locally, but can be slow/missing over SSH.
-- Keep them, but they just work when a clipboard provider exists.
map({ "n", "v" }, "<leader>y", '"+y', { desc = "Yank to clipboard" })
map("n", "<leader>Y", '"+Y', { desc = "Yank line to clipboard" })
map({ "n", "v" }, "<leader>p", '"+p', { desc = "Paste from clipboard" })

map("v", "<", "<gv")
map("v", ">", ">gv")

map("n", "<A-j>", "<cmd>m .+1<cr>==", { desc = "Move down" })
map("n", "<A-k>", "<cmd>m .-2<cr>==", { desc = "Move up" })
map("v", "<A-j>", ":m '>+1<cr>gv=gv", { desc = "Move down" })
map("v", "<A-k>", ":m '<-2<cr>gv=gv", { desc = "Move up" })

map("n", "[q", "<cmd>cprev<cr>", { desc = "Prev quickfix" })
map("n", "]q", "<cmd>cnext<cr>", { desc = "Next quickfix" })
map("n", "<leader>qo", "<cmd>copen<cr>", { desc = "Open quickfix" })
map("n", "<leader>qc", "<cmd>cclose<cr>", { desc = "Close quickfix" })
map("n", "[l", "<cmd>lprev<cr>", { desc = "Prev location" })
map("n", "]l", "<cmd>lnext<cr>", { desc = "Next location" })

map("n", "<F3>", toggle_number, { desc = "Cycle number modes" })

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
  table.insert(info, "Configured: " .. table.concat(lsp_servers, ", "))
  table.insert(info, "Log: " .. vim.lsp.get_log_path())

  vim.notify(table.concat(info, "\n"), vim.log.levels.INFO)
end, { desc = "LSP info" })

map("n", "<leader>c", function()
  vim.cmd.edit(vim.fn.stdpath("config") .. "/init_minimal.lua")
end, { desc = "Edit config" })

-- Help: show custom keymaps (minimal, kept in sync with this file)
map("n", "<leader>?", function()
  local help = {
    "═══════════════════════════════════════════════════════════",
    "                    CUSTOM KEYMAPS",
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
    "  [e / ]e        Prev/Next error",
    "  <C-W>d         Show diagnostic float",
    "",
    "GIT (prefix: <leader>g)",
    "  [c / ]c        Prev/Next hunk",
    "  <leader>hp     Preview hunk",
    "  <leader>hs     Stage hunk",
    "  <leader>hu     Unstage hunk",
    "  <leader>hr     Reset hunk",
    "  <leader>gd     Diff file (vs HEAD)",
    "  <leader>gD     Diff repo (vs HEAD)",
    "  <leader>ga     Stage buffer",
    "  <leader>gA     Stage all",
    "  <leader>gu     Unstage buffer",
    "  <leader>gR     Reset buffer",
    "  <leader>gb     Blame",
    "  <leader>gl     Log",
    "  <leader>gs     Status",
    "  <leader>gC     Commit",
    "  <leader>gP     Push",
    "",
    "NAVIGATION (prefix: <leader>f)",
    "  <leader>ff     Find files",
    "  <leader>fp     Find by pattern",
    "  <leader>fg     Search in files (grep)",
    "  <leader>fw     Search word under cursor",
    "  <leader>fb     Buffer list",
    "  <leader>fr     Recent files",
    "  <leader>fm     Marks list",
    "  <leader><leader> Alternate file (last 2)",
    "  <leader>e      Explorer sidebar (netrw)",
    "  -              Browse current directory (tab)",
    "",
    "WINDOWS",
    "  <C-h/j/k/l>    Navigate windows",
    "  <leader>-      Split horizontal",
    "  <leader>|      Split vertical",
    "",
    "BUFFERS",
    "  <Tab>/<S-Tab>  Next/Prev buffer",
    "  <leader>bd     Delete buffer",
    "  <leader>bo     Close hidden buffers",
    "",
    "COMPLETION",
    "  <Tab>          Complete (omni/keyword)",
    "  <S-Tab>        Previous item",
    "  <Enter>        Accept",
    "  <C-x><C-f>     File paths",
    "  <F2>           Toggle auto-trigger",
    "",
    "EDITING",
    "  <leader>sw     Strip whitespace",
    "  <leader>st     Set tab width",
    "  <A-j/k>        Move line(s) down/up",
    "",
    "MISC",
    "  <leader>t      Terminal",
    "  <Esc><Esc>     Exit terminal mode",
    "  <leader>r      Run file (simple)",
    "  <F3>           Cycle number modes",
    "",
    "COMMANDS",
    "  :StripWhitespace    Remove trailing whitespace",
    "  :SetTab [width]    Set tab/indent width",
    "  :CloseHiddenBuffers Close all hidden buffers",
    "  :ToggleNumber      Cycle number display modes",
    "",
    "═══════════════════════════════════════════════════════════",
    "  Press 'q' or <Esc> to close",
  }

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, help)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"

  local width = 65
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

  map("n", "q", "<cmd>close<cr>", { buffer = buf })
  map("n", "<Esc>", "<cmd>close<cr>", { buffer = buf })
end, { desc = "Show keymaps" })

-- Quick "run file" helper (kept simple)
map("n", "<leader>r", function()
  local ft = vim.bo.filetype
  local file = vim.fn.shellescape(vim.fn.expand("%:p"))

  local cmds = {
    python = "python3 " .. file,
    sh = "bash " .. file,
    bash = "bash " .. file,
    c = "gcc " .. file .. " -o /tmp/a.out && /tmp/a.out",
    rust = "cargo run",
  }

  local cmd = cmds[ft]
  if cmd then
    vim.cmd("terminal " .. cmd)
  else
    print("No run command for: " .. ft)
  end
end, { desc = "Run file" })

-- ============================================================================
-- AUTOCOMMANDS
-- ============================================================================

vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function() vim.highlight.on_yank({ higroup = "IncSearch", timeout = 200 }) end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "yaml", "yml" },
  callback = function() vim.bo.commentstring = "# %s" end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "qf",
  callback = function()
    vim.keymap.set("n", "q", "<cmd>cclose<cr><cmd>lclose<cr>", { buffer = true, silent = true })
  end,
})

vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(0) then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

vim.api.nvim_create_autocmd("TermClose", {
  callback = function() vim.cmd("bdelete!") end,
})

-- Reload this file on write (no module games)
local crg = vim.api.nvim_create_augroup("configReload", { clear = true })
vim.api.nvim_create_autocmd("BufWritePost", {
  group = crg,
  pattern = "init_minimal.lua",
  callback = function(ev)
    if ev.file == "" then return end
    pcall(vim.cmd, "source " .. vim.fn.fnameescape(ev.file))
    vim.notify("init_minimal.lua reloaded", vim.log.levels.INFO)
  end,
})
