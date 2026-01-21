-- Minimal Neovim Config (0.11+, plugin-free)
-- Native: gd gD grr gri gO K grn gra [d ]d <C-W>d gc gcc ]c [c do dp <C-L> Y Q ZZ

local o, g, map = vim.opt, vim.g, vim.keymap.set
g.mapleader = " "
g.maplocalleader = " "

-- Settings
o.number = true
o.relativenumber = true
o.cursorline = true
o.signcolumn = "auto"
o.expandtab = true
o.shiftwidth = 4
o.tabstop = 4
o.smartindent = true
o.ignorecase = true
o.smartcase = true
o.hlsearch = true
o.splitright = true
o.splitbelow = true
o.wrap = false
o.scrolloff = 8
o.swapfile = false
o.backup = false
o.updatetime = 300
o.timeoutlen = 500
o.completeopt = "menu,menuone,noselect"
o.pumheight = 10
o.list = true
o.listchars = { tab = "| ", trail = ".", nbsp = "+" }
o.mouse = ""
o.showmode = false
o.diffopt:append({ "vertical", "linematch:60", "algorithm:histogram" })

if vim.fn.executable("rg") == 1 then
  vim.o.grepprg = "rg --vimgrep --smart-case"
end

pcall(vim.cmd, "colorscheme retrobox")

-- LSP (native: gd gD grr gri gO K grn gra)
vim.lsp.enable({ "bashls", "pyright", "clangd", "rust_analyzer", "jdtls" })

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"
    map("n", "gry", vim.lsp.buf.type_definition, { buffer = ev.buf })
    map("n", "grf", function() vim.lsp.buf.format({ async = true }) end, { buffer = ev.buf })
  end,
})

-- Diagnostics (native: [d ]d <C-W>d)
vim.diagnostic.config({
  virtual_text = { prefix = ">" },
  float = { border = "rounded", source = true },
})

map("n", "[e", function() vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.ERROR }) end)
map("n", "]e", function() vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.ERROR }) end)

-- Completion
map("i", "<Tab>", function()
  if vim.fn.pumvisible() == 1 then return "<C-n>" end
  local col = vim.fn.col(".") - 1
  if col == 0 or vim.fn.getline("."):sub(col, col):match("%s") then return "<Tab>" end
  return vim.bo.omnifunc ~= "" and "<C-x><C-o>" or "<C-n>"
end, { expr = true })

map("i", "<S-Tab>", function()
  return vim.fn.pumvisible() == 1 and "<C-p>" or "<S-Tab>"
end, { expr = true })

map("i", "<CR>", function()
  return vim.fn.pumvisible() == 1 and "<C-y>" or "<CR>"
end, { expr = true })

-- Auto-trigger completion (toggle with F2)
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
end)

-- Toggle line numbers (F3)
map("n", "<F3>", function()
  o.number = not o.number:get()
  o.relativenumber = not o.relativenumber:get()
  print("Line numbers: " .. (o.number:get() and "ON" or "OFF"))
end)

-- File explorer (netrw)
g.netrw_banner = 0
g.netrw_liststyle = 3

map("n", "<leader>e", "<cmd>Lexplore<cr>")
map("n", "-", "<cmd>Explore<cr>")

-- File finder
local function ui_select(items, prompt, on_choice)
  if #items == 0 then return print("None found") end
  vim.ui.select(items, { prompt = prompt }, function(c)
    if c then on_choice(c) end
  end)
end

map("n", "<leader>ff", function()
  local cmd = vim.fn.executable("fd") == 1
    and "fd -tf -H -E.git"
    or "find . -type f ! -path '*/.git/*'"
  ui_select(vim.fn.systemlist(cmd), "File:", function(f)
    vim.cmd("e " .. vim.fn.fnameescape(f))
  end)
end)

map("n", "<leader>fr", function()
  local recent = vim.tbl_filter(function(f)
    return vim.fn.filereadable(f) == 1
  end, vim.v.oldfiles)
  ui_select(vim.list_slice(recent, 1, 30), "Recent:", function(f)
    vim.cmd("e " .. f)
  end)
end)

map("n", "<leader>fb", function()
  local bufs = {}
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[b].buflisted and vim.api.nvim_buf_get_name(b) ~= "" then
      table.insert(bufs, vim.api.nvim_buf_get_name(b))
    end
  end
  ui_select(bufs, "Buffer:", function(f)
    vim.cmd("e " .. f)
  end)
end)

map("n", "<leader>fg", function()
  local s = vim.fn.input("Grep: ")
  if s == "" then return end
  vim.cmd("silent grep! " .. vim.fn.shellescape(s))
  vim.cmd("copen")
end)

map("n", "<leader><leader>", "<C-^>")

-- Git
if vim.fn.executable("git") == 1 then
  local function git_file()
    return vim.fn.shellescape(vim.api.nvim_buf_get_name(0))
  end

  local function git_rel()
    local r = vim.fn.systemlist("git ls-files --full-name " .. git_file())[1]
    return (r and r ~= "" and vim.v.shell_error == 0) and r or nil
  end

  local function close_scratch()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.api.nvim_buf_is_valid(buf) and vim.b[buf].is_scratch then
        pcall(vim.api.nvim_win_close, win, false)
      end
    end
  end

  local function make_scratch(lines, ft, diff_mode)
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
    vim.bo.buftype = "nofile"
    vim.bo.bufhidden = "wipe"
    vim.bo.modifiable = false
    vim.b.is_scratch = true
    if ft then vim.bo.filetype = ft end
    if diff_mode then vim.cmd("diffthis") end
    map("n", "q", close_scratch, { buffer = true })
  end

  local function scratch(lines, ft)
    vim.cmd("tabnew")
    make_scratch(lines, ft, false)
  end

  -- Signs
  vim.fn.sign_define("GitAdd", { text = "+", texthl = "DiffAdd" })
  vim.fn.sign_define("GitChange", { text = "~", texthl = "DiffChange" })
  vim.fn.sign_define("GitDelete", { text = "_", texthl = "DiffDelete" })

  local function update_signs(buf)
    if vim.bo[buf].buftype ~= "" or vim.api.nvim_buf_get_name(buf) == "" then return end
    vim.fn.sign_unplace("git", { buffer = buf })

    local diff = vim.fn.systemlist({ "git", "diff", "-U0", "--", vim.api.nvim_buf_get_name(buf) })
    for _, line in ipairs(diff) do
      local os, oc, ns, nc = line:match("^@@%s*%-(%d+),?(%d*)%s*%+(%d+),?(%d*)%s*@@")
      if ns then
        os, oc = tonumber(os), tonumber(oc ~= "" and oc or 1)
        ns, nc = tonumber(ns), tonumber(nc ~= "" and nc or 1)

        local sign
        if oc == 0 and nc > 0 then
          sign = "GitAdd"
        elseif nc == 0 and oc > 0 then
          sign = "GitDelete"
        else
          sign = "GitChange"
        end

        if nc > 0 then
          for l = ns, ns + nc - 1 do
            vim.fn.sign_place(0, "git", sign, buf, { lnum = l, priority = 5 })
          end
        else
          -- Deletion: show on the line where deletion occurred
          vim.fn.sign_place(0, "git", sign, buf, { lnum = ns, priority = 5 })
        end
      end
    end
  end

  vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
    callback = function(ev)
      vim.defer_fn(function() update_signs(ev.buf) end, 100)
    end,
  })

  -- Hunks
  local function get_hunks()
    local rel = git_rel()
    if not rel then return {} end

    local diff = vim.fn.systemlist("git diff -U0 -- " .. git_file())
    local hunks = {}

    for i, line in ipairs(diff) do
      local os, oc, ns, nc = line:match("^@@%s*%-(%d+),?(%d*)%s*%+(%d+),?(%d*)%s*@@")
      if ns then
        local lines = { line }
        for j = i + 1, #diff do
          if diff[j]:match("^@@") then break end
          table.insert(lines, diff[j])
        end
        table.insert(hunks, {
          start = tonumber(ns),
          count = tonumber(nc ~= "" and nc or 1),
          old_start = tonumber(os),
          old_count = tonumber(oc ~= "" and oc or 1),
          lines = lines,
          rel = rel,
        })
      end
    end
    return hunks
  end

  local function hunk_at_cursor()
    local cur = vim.api.nvim_win_get_cursor(0)[1]
    for _, h in ipairs(get_hunks()) do
      local e = h.count == 0 and h.start or (h.start + h.count - 1)
      if cur >= h.start and cur <= e then return h end
    end
  end

  local function make_patch(h, reverse)
    local patch = { "--- a/" .. h.rel, "+++ b/" .. h.rel }
    for _, line in ipairs(h.lines) do
      if reverse then
        if line:match("^%+") and not line:match("^%+%+%+") then
          line = "-" .. line:sub(2)
        elseif line:match("^%-") and not line:match("^%-%-%-") then
          line = "+" .. line:sub(2)
        elseif line:match("^@@") then
          line = string.format("@@ -%d,%d +%d,%d @@", h.start, h.count, h.old_start, h.old_count)
        end
      end
      table.insert(patch, line)
    end
    return table.concat(patch, "\n") .. "\n"
  end

  map("n", "<leader>hp", function()
    local h = hunk_at_cursor()
    if not h then return print("No hunk") end

    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_open_win(buf, true, {
      relative = "cursor",
      row = 1,
      col = 0,
      width = 70,
      height = math.min(#h.lines, 15),
      style = "minimal",
      border = "rounded",
    })
    make_scratch(h.lines, "diff", false)
  end)

  map("n", "<leader>hs", function()
    local h = hunk_at_cursor()
    if not h then return print("No hunk") end

    vim.fn.system("git apply --cached --unidiff-zero -", make_patch(h, false))
    print(vim.v.shell_error == 0 and "Staged hunk" or "Failed")
    update_signs(vim.api.nvim_get_current_buf())
  end)

  map("n", "<leader>hr", function()
    local h = hunk_at_cursor()
    if not h then return print("No hunk") end

    vim.fn.system("git apply --unidiff-zero -", make_patch(h, true))
    if vim.v.shell_error == 0 then
      vim.cmd("e!")
      print("Reset hunk")
    else
      print("Failed")
    end
  end)

  -- Hunk navigation
  local function next_hunk()
    local hunks = get_hunks()
    if #hunks == 0 then return print("No hunks") end
    local cur = vim.api.nvim_win_get_cursor(0)[1]
    for _, h in ipairs(hunks) do
      if h.start > cur then
        vim.api.nvim_win_set_cursor(0, { h.start, 0 })
        return
      end
    end
    print("No more hunks")
  end

  local function prev_hunk()
    local hunks = get_hunks()
    if #hunks == 0 then return print("No hunks") end
    local cur = vim.api.nvim_win_get_cursor(0)[1]
    for i = #hunks, 1, -1 do
      local h = hunks[i]
      if h.start < cur then
        vim.api.nvim_win_set_cursor(0, { h.start, 0 })
        return
      end
    end
    print("No more hunks")
  end

  map("n", "]h", next_hunk)
  map("n", "[h", prev_hunk)

  -- Inline diff
  local ns = vim.api.nvim_create_namespace("inline_diff")
  local inline_on = {}

  map("n", "<leader>hi", function()
    local buf = vim.api.nvim_get_current_buf()
    inline_on[buf] = not inline_on[buf]
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)

    if not inline_on[buf] then
      return print("Inline diff: OFF")
    end

    local diff = vim.fn.systemlist("git diff -U0 -- " .. git_file())
    local i = 1
    while i <= #diff do
      local _, new_start = diff[i]:match("^@@.-%-(%d+),?%d*%s*%+(%d+),?%d*.-@@")
      if new_start then
        local deleted = {}
        i = i + 1
        while i <= #diff and not diff[i]:match("^@@") do
          if diff[i]:match("^%-") and not diff[i]:match("^%-%-%-") then
            table.insert(deleted, { { diff[i], "DiffDelete" } })
          end
          i = i + 1
        end
        if #deleted > 0 then
          pcall(vim.api.nvim_buf_set_extmark, buf, ns, tonumber(new_start) - 1, 0, {
            virt_lines = deleted,
            virt_lines_above = true,
          })
        end
      else
        i = i + 1
      end
    end
    print("Inline diff: ON")
  end)

  -- Git commands

  local function resolve_conflict(buf, choice)
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local cur = vim.api.nvim_win_get_cursor(0)[1]
    local s, m, e, f
    for i = cur, 1, -1 do if lines[i]:match("^<<<<<<<") then s = i; break end end
    if not s then return print("Not in conflict") end
    for i = s, #lines do
      if lines[i]:match("^|||||||") then m = i
      elseif lines[i]:match("^=======") then e = i
      elseif lines[i]:match("^>>>>>>>") then f = i; break end
    end
    if not e or not f then return print("Malformed conflict") end
    local result = {}
    local a, b
    if choice == "ours" then
      a, b = s + 1, (m or e) - 1
    elseif choice == "theirs" then
      a, b = e + 1, f - 1
    elseif choice == "base" then
      if not m then return print("No base section") end
      a, b = m + 1, e - 1
    end
    for i = a, b do table.insert(result, lines[i]) end
    vim.api.nvim_buf_set_lines(buf, s - 1, f, false, result)
  end

  map("n", "<leader>gd", function()
    local rel = git_rel()
    if not rel then return print("Not tracked") end

    -- Check for merge conflict
    local ours = vim.fn.systemlist("git show :2:" .. rel .. " 2>/dev/null")
    local theirs = vim.fn.systemlist("git show :3:" .. rel .. " 2>/dev/null")

    if #ours > 0 and #theirs > 0 then
      local file = vim.api.nvim_buf_get_name(0)
      vim.cmd("tabnew " .. vim.fn.fnameescape(file))
      local work_buf = vim.api.nvim_get_current_buf()
      local center = vim.api.nvim_get_current_win()

      vim.cmd("leftabove vnew")
      make_scratch(ours, nil, true)
      local ours_buf = vim.api.nvim_get_current_buf()

      vim.api.nvim_set_current_win(center)
      vim.cmd("rightbelow vnew")
      make_scratch(theirs, nil, true)
      local theirs_buf = vim.api.nvim_get_current_buf()

      vim.api.nvim_set_current_win(center)
      vim.cmd("diffthis")

      -- gh/gl = diffget hunk, gH/gL/gJ = resolve conflict block
      map("n", "gh", "<cmd>diffget " .. ours_buf .. "<cr>", { buffer = work_buf })
      map("n", "gl", "<cmd>diffget " .. theirs_buf .. "<cr>", { buffer = work_buf })
      map("n", "q", "<cmd>tabclose<cr>", { buffer = work_buf })
      return print("Merge: OURS | WORKING | THEIRS (gh/gl=hunk gH/gJ/gL=block | ]c/[c nav | q=quit)")
    end

    -- Normal diff against HEAD
    local head = vim.fn.systemlist("git show HEAD:" .. rel)
    if #head == 0 then return print("No HEAD") end

    local work_buf = vim.api.nvim_get_current_buf()
    vim.cmd("vnew")
    make_scratch(head, nil, true)
    vim.cmd("wincmd p | diffthis")
    map("n", "q", function()
      close_scratch()
      vim.cmd("diffoff")
    end, { buffer = work_buf })
  end)

  map("n", "<leader>gD", function()
    local rel = git_rel()
    if not rel then return print("Not tracked") end
    local diff = vim.fn.systemlist("git diff HEAD -- " .. git_file())
    if #diff == 0 then return print("No changes") end
    scratch(diff, "diff")
  end)

  map("n", "<leader>gs", "<cmd>!git status -s<cr>")

  map("n", "<leader>ga", function()
    vim.fn.system("git add " .. git_file())
    print("Staged")
    update_signs(0)
  end)

  map("n", "<leader>gu", function()
    vim.fn.system("git reset HEAD " .. git_file())
    print("Unstaged")
    update_signs(0)
  end)

  map("n", "<leader>gR", function()
    vim.fn.system("git checkout -- " .. git_file())
    vim.cmd("e!")
    print("Reset")
  end)

  map("n", "<leader>gb", function()
    scratch(vim.fn.systemlist("git blame --date=short " .. git_file()), nil)
  end)

  map("n", "<leader>gl", function()
    scratch(vim.fn.systemlist("git log --oneline -30 -- " .. git_file()), nil)
  end)

  map("n", "<leader>gL", function()
    scratch(vim.fn.systemlist("git log --oneline -30"), nil)
  end)

  map("n", "<leader>gC", "<cmd>terminal git commit<cr>")
  map("n", "<leader>gP", "<cmd>!git push<cr>")

  -- Global conflict resolution (works anywhere in conflict blocks)
  map("n", "gH", function() resolve_conflict(0, "ours") end)
  map("n", "gJ", function() resolve_conflict(0, "base") end)
  map("n", "gL", function() resolve_conflict(0, "theirs") end)
end

-- Keymaps
map("n", "<Esc>", "<cmd>noh<cr>")
map("n", "<leader>w", "<cmd>w<cr>")
map("n", "<leader>q", "<cmd>q<cr>")
map("n", "<leader>Q", "<cmd>qa<cr>")

map("n", "<C-h>", "<C-w>h")
map("n", "<C-j>", "<C-w>j")
map("n", "<C-k>", "<C-w>k")
map("n", "<C-l>", "<C-w>l")

map("n", "<Tab>", "<cmd>bn<cr>")
map("n", "<S-Tab>", "<cmd>bp<cr>")
map("n", "<leader>bd", "<cmd>bd<cr>")

map("n", "<leader>t", "<cmd>term<cr>")
map("t", "<Esc><Esc>", "<C-\\><C-n>")

map({ "n", "v" }, "<leader>y", '"+y')
map({ "n", "v" }, "<leader>p", '"+p')

map("v", "<", "<gv")
map("v", ">", ">gv")

map("n", "<A-j>", "<cmd>m .+1<cr>==")
map("n", "<A-k>", "<cmd>m .-2<cr>==")
map("v", "<A-j>", ":m '>+1<cr>gv=gv")
map("v", "<A-k>", ":m '<-2<cr>gv=gv")

map("n", "[q", "<cmd>cprev<cr>")
map("n", "]q", "<cmd>cnext<cr>")

map("n", "<leader>c", function()
  vim.cmd("e " .. vim.fn.stdpath("config") .. "/init_minimal.lua")
end)

-- Run file
map("n", "<leader>r", function()
  local ft = vim.bo.filetype
  local file = vim.fn.shellescape(vim.fn.expand("%:p"))
  local cmds = {
    python = "python3 " .. file,
    sh = "bash " .. file,
    bash = "bash " .. file,
    lua = "lua " .. file,
    c = "gcc " .. file .. " -o /tmp/a.out && /tmp/a.out",
    rust = "cargo run",
  }
  local cmd = cmds[ft]
  if cmd then
    vim.cmd("terminal " .. cmd)
  else
    print("No run command for: " .. ft)
  end
end)

-- Utilities
map("n", "<leader>sw", function()
  local v = vim.fn.winsaveview()
  vim.cmd([[%s/\s\+$//e]])
  vim.fn.winrestview(v)
  print("Stripped whitespace")
end)

map("n", "<leader>st", function()
  local n = tonumber(vim.fn.input("Tab width: "))
  if n then
    vim.bo.tabstop = n
    vim.bo.shiftwidth = n
  end
end)

map("n", "<leader>bo", function()
  local visible = {}
  for _, w in ipairs(vim.api.nvim_list_wins()) do
    visible[vim.api.nvim_win_get_buf(w)] = true
  end

  local closed = 0
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(b) and not visible[b] and vim.bo[b].buftype == "" then
      pcall(vim.api.nvim_buf_delete, b, {})
      closed = closed + 1
    end
  end
  print("Closed " .. closed .. " hidden buffers")
end)

-- Autocommands
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function() vim.highlight.on_yank() end,
})

vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function()
    local m = vim.api.nvim_buf_get_mark(0, '"')
    if m[1] > 0 and m[1] <= vim.api.nvim_buf_line_count(0) then
      pcall(vim.api.nvim_win_set_cursor, 0, m)
    end
  end,
})

vim.api.nvim_create_autocmd("TermClose", {
  callback = function() vim.cmd("bd!") end,
})

-- Help
map("n", "<leader>?", function()
  print([[
CUSTOM:   w/q/Q save/quit | ff/fr/fb/fg find | e/- explore | y/p clip | bd/bo buf | Tab nav | C-hjkl win | c config
GIT:      gd diff/merge gD diff(tab) | gs/gC/gP status/commit/push | ga/gu stage/unstage | gR reset | gb/gl blame/log
HUNK:     hp preview | hs stage | hr reset | hi inline | ]h/[h next/prev hunk
CONFLICT: gH/gJ/gL resolve block (ours/base/theirs) | MISC: r run | sw strip | st tab | F2 auto-cmp | F3 numbers
NATIVE:   gd/gD/grr/gri/K/grn/gra LSP | [d/]d [e/]e diag | ]c/[c diff | gc comment | <C-L> clear | ZZ quit]])
end)
