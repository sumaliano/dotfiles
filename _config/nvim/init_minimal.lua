-- :G command: alias for any git command
vim.api.nvim_create_user_command('G', function(opts)
  local git_cmd = table.concat(opts.fargs, ' ')
  if git_cmd == '' then
    print('Usage: :G <git-args>')
    return
  end
  vim.cmd('terminal git ' .. git_cmd)
end, { nargs = '+', complete = 'shellcmd' })

-- Shortcuts
local o, g, map = vim.opt, vim.g, vim.keymap.set
g.mapleader, g.maplocalleader = " ", " "

for k, v in pairs {
  number = true,
  relativenumber = true,
  cursorline = true,
  signcolumn = "auto",
  expandtab = true,
  shiftwidth = 4,
  tabstop = 4,
  smartindent = true,
  ignorecase = true,
  smartcase = true, 
  hlsearch = true,
  splitright = true, 
  splitbelow = true, 
  wrap = false, 
  scrolloff = 8,
  swapfile = false, 
  backup = false, 
  updatetime = 300, 
  timeoutlen = 500,
  completeopt = "menu,menuone,noselect", 
  pumheight = 10, 
  list = true,
  mouse = "", 
  showmode = false, 
  laststatus = 2,
  termguicolors = true
} do o[k] = v end
o.listchars = { tab = "| ", trail = ".", nbsp = "+" }
o.diffopt:append { "vertical", "linematch:60", "algorithm:histogram", "indent-heuristic", "internal" }

-- Ensure default runtime is in runtimepath for default colorschemes
local default_runtime = vim.fn.stdpath('data') .. '/runtime'
if not string.find(vim.o.runtimepath, default_runtime, 1, true) then
  vim.o.runtimepath = default_runtime .. ',' .. vim.o.runtimepath
end


if vim.fn.executable("rg") == 1 then o.grepprg = "rg --vimgrep --smart-case" end

pcall(vim.cmd, "colorscheme retrobox")

-- Statusline
local cached_branch = ""
local function update_branch()
  cached_branch = vim.fn.system("git branch --show-current 2>/dev/null"):gsub("\n", "")
end

local function statusline()
  local mode_map = { n = "N", i = "I", v = "V", V = "VL", ["\22"] = "VB", c = "C", R = "R", t = "T" }
  local mode = mode_map[vim.fn.mode()] or vim.fn.mode()
  local file = vim.fn.expand("%:~:.")
  if file == "" then file = "[No Name]" end
  local flags = vim.bo.modified and " [+]" or (not vim.bo.modifiable and " [-]" or "")
  local branch = cached_branch ~= "" and " " .. cached_branch or ""
  local lsp = #vim.lsp.get_clients({ bufnr = 0 }) > 0 and "LSP " or ""
  return " " .. mode .. " " .. branch .. " " .. file .. flags .. "%=" .. lsp .. "%l:%c %p%% "
end

vim.api.nvim_create_autocmd({ "BufEnter", "DirChanged" }, {
  callback = update_branch
})

_G.statusline_fn = statusline
vim.o.statusline = "%!v:lua.statusline_fn()"

-- LSP (native: gd gD grr gri gO K grn gra)
vim.lsp.enable({ "bashls", "pyright", "clangd", "rust_analyzer", "jdtls" })

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"
    map("n", "gry", vim.lsp.buf.type_definition, { buffer = ev.buf })
    map("n", "grf", function() vim.lsp.buf.format({ async = true }) end, { buffer = ev.buf })
  end,
})


-- Diagnostics
vim.diagnostic.config {
  virtual_text = { prefix = ">" },
  float = { border = "rounded", source = true },
}
map("n", "[e", function() vim.diagnostic.goto_prev { severity = vim.diagnostic.severity.ERROR } end)
map("n", "]e", function() vim.diagnostic.goto_next { severity = vim.diagnostic.severity.ERROR } end)


-- Completion
map("i", "<Tab>", function()
  if vim.fn.pumvisible() == 1 then return "<C-n>" end
  local col = vim.fn.col(".") - 1
  if col == 0 or vim.fn.getline("."):sub(col, col):match("%s") then return "<Tab>" end
  return vim.bo.omnifunc ~= "" and "<C-x><C-o>" or "<C-n>"
end, { expr = true })
map("i", "<S-Tab>", function() return vim.fn.pumvisible() == 1 and "<C-p>" or "<S-Tab>" end, { expr = true })
map("i", "<CR>", function() return vim.fn.pumvisible() == 1 and "<C-y>" or "<CR>" end, { expr = true })


-- Auto-trigger completion (toggle with F2)
local auto_cmp_group = vim.api.nvim_create_augroup("AutoCmp", { clear = true })
local auto_cmp = false
map("n", "<F2>", function()
  auto_cmp = not auto_cmp
  vim.api.nvim_clear_autocmds { group = auto_cmp_group }
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
  o.number, o.relativenumber = not o.number:get(), not o.relativenumber:get()
  print("Line numbers: " .. (o.number:get() and "ON" or "OFF"))
end)


-- File explorer (netrw)
g.netrw_banner, g.netrw_liststyle = 0, 3
map("n", "<leader>e", "<cmd>Lexplore<cr>")
map("n", "-", "<cmd>Explore<cr>")


-- File finder
local function ui_sel(items, prompt, on_choice)
  if #items == 0 then return print("None found") end
  vim.ui.select(items, { prompt = prompt }, function(c) if c then on_choice(c) end end)
end

map("n", "<leader>ff", function()
  local cmd = vim.fn.executable("fd") == 1 and "fd -tf -H -E.git" or "find . -type f ! -path '*/.git/*'"
  ui_sel(vim.fn.systemlist(cmd), "File:", function(f) vim.cmd("e " .. vim.fn.fnameescape(f)) end)
end)

map("n", "<leader>fr", function()
  local recent = vim.tbl_filter(function(f) return vim.fn.filereadable(f) == 1 end, vim.v.oldfiles)
  ui_sel(vim.list_slice(recent, 1, 30), "Recent:", function(f) vim.cmd("e " .. f) end)
end)

map("n", "<leader>fb", function()
  local bufs = {}
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[b].buflisted and vim.api.nvim_buf_get_name(b) ~= "" then
      table.insert(bufs, vim.api.nvim_buf_get_name(b))
    end
  end
  ui_sel(bufs, "Buffer:", function(f) vim.cmd("e " .. f) end)
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
  local function git_file() return vim.fn.shellescape(vim.api.nvim_buf_get_name(0)) end
  local function git_rel()
    local r = vim.fn.systemlist("git ls-files --full-name " .. git_file())[1]
    return (r and r ~= "" and vim.v.shell_error == 0) and r or nil
  end
  local function close_scratch()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.api.nvim_buf_is_valid(buf) and vim.b[buf].is_scratch then pcall(vim.api.nvim_win_close, win, false) end
    end
  end
  local function make_scratch(lines, ft, diff_mode)
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
    vim.bo.buftype, vim.bo.bufhidden, vim.b.is_scratch, vim.bo.modifiable = "nofile", "wipe", true, false
    vim.bo.filetype = "diff"
    if diff_mode then vim.cmd("diffthis") end
    map("n", "q", close_scratch, { buffer = true })
  end
  local function scratch(lines, ft) vim.cmd("tabnew"); make_scratch(lines, ft, false) end

  -- Signs with Claude Code-style colors
  local function set_git_highlights()
    vim.api.nvim_set_hl(0, "GitSignAdd", { fg = "#2ea043", bold = true })
    vim.api.nvim_set_hl(0, "GitSignChange", { fg = "#d29922", bold = true })
    vim.api.nvim_set_hl(0, "GitSignDelete", { fg = "#f85149", bold = true })
    vim.api.nvim_set_hl(0, "GitLineAdd", { bg = "#1d3b2a" })
    vim.api.nvim_set_hl(0, "GitLineChange", { bg = "#3b3520" })
    vim.api.nvim_set_hl(0, "GitLineDelete", { bg = "#3b1d1d" })
    -- Vim diff mode highlights (for split diff view)
    -- GitHub/GitLab/Claude-style diff colors
    vim.api.nvim_set_hl(0, "DiffAdd", { bg = "#1d3b2a" })
    vim.api.nvim_set_hl(0, "DiffChange", { bg = "#2a2a20" })
    vim.api.nvim_set_hl(0, "DiffDelete", { bg = "#3b1d1d", fg = "#5c3030" })
    vim.api.nvim_set_hl(0, "DiffText", { bg = "#3b3520" })
  end

  set_git_highlights()
  vim.api.nvim_create_autocmd("ColorScheme", { callback = set_git_highlights })

  vim.fn.sign_define("GitAdd", { text = "▎", texthl = "GitSignAdd" })
  vim.fn.sign_define("GitChange", { text = "▎", texthl = "GitSignChange" })
  vim.fn.sign_define("GitDelete", { text = "▁", texthl = "GitSignDelete" })
  -- vim.fn.sign_define("GitAdd", { text = "+", texthl = "DiffAdd" })
  -- vim.fn.sign_define("GitChange", { text = "~", texthl = "DiffChange" })
  -- vim.fn.sign_define("GitDelete", { text = "_", texthl = "DiffDelete" })

  -- Cache HEAD content per buffer and debounce timer
  local head_cache = {}
  local debounce_timers = {}

  local function refresh_head_cache(buf)
    local name = vim.api.nvim_buf_get_name(buf)
    if vim.bo[buf].buftype ~= "" or name == "" then return end

    local rel = vim.fn.systemlist("git ls-files --full-name " .. vim.fn.shellescape(name))[1]
    if not rel or rel == "" or vim.v.shell_error ~= 0 then
      head_cache[buf] = nil
      return
    end

    -- Compare against last commit
    -- local head = vim.fn.system("git show HEAD:" .. rel)
    -- Compare against index (:0:) to show only unstaged changes
    local head = vim.fn.system("git show :0:" .. rel)
    if vim.v.shell_error ~= 0 then
      head_cache[buf] = nil
      return
    end

    head_cache[buf] = head
  end

  local function update_signs(buf)
    if not vim.api.nvim_buf_is_valid(buf) then return end
    local head = head_cache[buf]
    if not head then return end

    vim.fn.sign_unplace("git", { buffer = buf })

    -- Get buffer content
    local buf_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local buf_content = table.concat(buf_lines, "\n") .. "\n"

    -- Compute diff using vim.diff (compares buffer to HEAD)
    local hunks = vim.diff(head, buf_content, { result_type = "indices" })

    for _, hunk in ipairs(hunks) do
      local old_count, new_start, new_count = hunk[2], hunk[3], hunk[4]

      local sign
      if old_count == 0 and new_count > 0 then
        sign = "GitAdd"
      elseif new_count == 0 and old_count > 0 then
        sign = "GitDelete"
      else
        sign = "GitChange"
      end

      if new_count > 0 then
        for l = new_start, new_start + new_count - 1 do
          vim.fn.sign_place(0, "git", sign, buf, { lnum = l, priority = 5 })
        end
      else
        -- Deletion: place sign on nearest valid line
        local line_count = vim.api.nvim_buf_line_count(buf)
        local lnum = math.max(1, math.min(new_start, line_count))
        vim.fn.sign_place(0, "git", sign, buf, { lnum = lnum, priority = 5 })
      end
    end
  end

  local function debounced_update(buf, delay)
    if debounce_timers[buf] then
      vim.fn.timer_stop(debounce_timers[buf])
    end
    debounce_timers[buf] = vim.fn.timer_start(delay, function()
      debounce_timers[buf] = nil
      vim.schedule(function() update_signs(buf) end)
    end)
  end

  -- Refresh cache on buffer enter, write, and focus
  vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "FocusGained" }, {
    callback = function(ev)
      refresh_head_cache(ev.buf)
      update_signs(ev.buf)
    end,
  })

  -- Debounced updates on text changes (fast diff, no git calls)
  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    callback = function(ev)
      debounced_update(ev.buf, 150)
    end,
  })

  -- Cleanup cache on buffer delete
  vim.api.nvim_create_autocmd("BufDelete", {
    callback = function(ev)
      head_cache[ev.buf] = nil
      if debounce_timers[ev.buf] then
        vim.fn.timer_stop(debounce_timers[ev.buf])
        debounce_timers[ev.buf] = nil
      end
    end,
  })

  -- Hunks
  local function get_hunks(staged)
    local rel = git_rel()
    if not rel then return {} end

    local cmd = staged and "git diff --cached -U0 -- " or "git diff -U0 -- "
    local diff = vim.fn.systemlist(cmd .. git_file())
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

  local function hunk_at_cursor(staged)
    local cur = vim.api.nvim_win_get_cursor(0)[1]
    for _, h in ipairs(get_hunks(staged)) do
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

  map("n", "<leader>ha", function()
    local h = hunk_at_cursor(false)
    if not h then return print("No hunk") end

    vim.fn.system("git apply --cached --unidiff-zero -", make_patch(h, false))
    print(vim.v.shell_error == 0 and "Staged hunk" or "Failed")

    refresh_head_cache(vim.api.nvim_get_current_buf())
    update_signs(vim.api.nvim_get_current_buf())
  end)

  map("n", "<leader>hu", function()
    local h = hunk_at_cursor(true) or hunk_at_cursor(false)
    if not h then return print("No hunk") end

    vim.fn.system("git apply --cached --unidiff-zero -", make_patch(h, true))
    print(vim.v.shell_error == 0 and "Unstaged hunk" or "Failed")

    refresh_head_cache(vim.api.nvim_get_current_buf())
    update_signs(vim.api.nvim_get_current_buf())
  end)

  map("n", "<leader>hr", function()
    local h = hunk_at_cursor(false)
    if not h then return print("No hunk") end

    vim.fn.system("git apply --unidiff-zero -", make_patch(h, true))
    if vim.v.shell_error == 0 then
      vim.cmd("e!")
      print("Reset hunk to index (unstaged)")
      refresh_head_cache(vim.api.nvim_get_current_buf())
      update_signs(vim.api.nvim_get_current_buf())
    else
      print("Failed")
    end
  end)

  map("n", "<leader>hR", function()
    local h = hunk_at_cursor(true) or hunk_at_cursor(false)
    if not h then return print("No hunk") end

    -- Unstage first, then reset
    vim.fn.system("git apply --cached --unidiff-zero -", make_patch(h, true))
    vim.fn.system("git apply --unidiff-zero -", make_patch(h, true))
    if vim.v.shell_error == 0 then
      vim.cmd("e!")
      print("Reset hunk to HEAD (all)")
      refresh_head_cache(vim.api.nvim_get_current_buf())
      update_signs(vim.api.nvim_get_current_buf())
    else
      print("Failed")
    end
  end)

  -- Hunk navigation
  map("n", "]c", function()
    local hunks, cur = get_hunks(), vim.api.nvim_win_get_cursor(0)[1]
    if #hunks == 0 then return print("No hunks") end
    for _, h in ipairs(hunks) do if h.start > cur then return vim.api.nvim_win_set_cursor(0, { h.start, 0 }) end end
    print("No more hunks")
  end)
  map("n", "[c", function()
    local hunks, cur = get_hunks(), vim.api.nvim_win_get_cursor(0)[1]
    if #hunks == 0 then return print("No hunks") end
    for i = #hunks, 1, -1 do if hunks[i].start < cur then return vim.api.nvim_win_set_cursor(0, { hunks[i].start, 0 }) end end
    print("No more hunks")
  end)

  -- Inline diff
  local ns = vim.api.nvim_create_namespace("inline_diff")
  local inline_on = {}

  map("n", "<leader>gi", function()
    local buf = vim.api.nvim_get_current_buf()
    inline_on[buf] = not inline_on[buf]
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)

    if not inline_on[buf] then
      return print("Inline diff: OFF")
    end

    local head = head_cache[buf]
    if not head then
      return print("No git HEAD")
    end

    -- Get buffer content and compute diff
    local buf_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local buf_content = table.concat(buf_lines, "\n") .. "\n"
    local diff = vim.diff(head, buf_content, { result_type = "unified" })
    if not diff or diff == "" then
      return print("No changes")
    end

    local diff_lines = vim.split(diff, "\n")
    local i = 1
    while i <= #diff_lines do
      local old_start, old_count, new_start, new_count =
        diff_lines[i]:match("^@@%s*%-(%d+),?(%d*)%s*%+(%d+),?(%d*)%s*@@")
      if new_start then
        old_count = tonumber(old_count ~= "" and old_count or 1)
        new_start = tonumber(new_start)
        new_count = tonumber(new_count ~= "" and new_count or 1)

        local deleted = {}
        i = i + 1
        local added_lines = {}

        while i <= #diff_lines and not diff_lines[i]:match("^@@") do
          local line = diff_lines[i]
          if line:match("^%-") then
            table.insert(deleted, { { "  " .. line:sub(2), "GitLineDelete" } })
          elseif line:match("^%+") then
            table.insert(added_lines, true)
          end
          i = i + 1
        end

        -- Show deleted lines as virtual text above
        if #deleted > 0 then
          local mark_line = math.max(0, new_start - 1)
          pcall(vim.api.nvim_buf_set_extmark, buf, ns, mark_line, 0, {
            virt_lines = deleted,
            virt_lines_above = true,
          })
        end

        -- Highlight added/changed lines
        local hl = old_count == 0 and "GitLineAdd" or "GitLineChange"
        for l = new_start, new_start + new_count - 1 do
          pcall(vim.api.nvim_buf_set_extmark, buf, ns, l - 1, 0, {
            line_hl_group = hl,
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
    local lines, cur, s, m, e, f = vim.api.nvim_buf_get_lines(buf, 0, -1, false), vim.api.nvim_win_get_cursor(0)[1]
    for i = cur, 1, -1 do if lines[i]:match("^<<<<<<<") then s = i; break end end
    if not s then return print("Not in conflict") end
    for i = s, #lines do
      if lines[i]:match("^|||||||") then m = i elseif lines[i]:match("^=======") then e = i elseif lines[i]:match("^>>>>>>>") then f = i; break end
    end
    if not e or not f then return print("Malformed conflict") end
    local a, b = choice == "ours" and { s + 1, (m or e) - 1 } or choice == "theirs" and { e + 1, f - 1 } or (m and { m + 1, e - 1 } or nil)
    if not a then return print("No base section") end
    local result = {}
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
      vim.wo.foldcolumn = "0"
      local ours_buf = vim.api.nvim_get_current_buf()

      vim.api.nvim_set_current_win(center)
      vim.cmd("rightbelow vnew")
      make_scratch(theirs, nil, true)
      vim.wo.foldcolumn = "0"
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
    vim.wo.foldcolumn = "0"
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
    vim.fn.system("git restore --staged " .. git_file())
    print("Unstaged")
    update_signs(0)
  end)

  map("n", "<leader>gr", function()
    vim.fn.system("git restore " .. git_file())
    vim.cmd("e!")
    print("Reset file to index (unstaged)")
    local buf = vim.api.nvim_get_current_buf()
    refresh_head_cache(buf)
    update_signs(buf)
  end)

  map("n", "<leader>gR", function()
    vim.fn.system("git restore --staged " .. git_file() .. " && git restore " .. git_file())
    vim.cmd("e!")
    print("Reset file to HEAD (all)")
    local buf = vim.api.nvim_get_current_buf()
    refresh_head_cache(buf)
    update_signs(buf)
  end)

  map("n", "<leader>gb", function()
    scratch(vim.fn.systemlist("git blame --date=short " .. git_file()), nil)
  end)

  map("n", "<leader>gl", function()
    local rel = git_rel()
    if not rel then return print("Not tracked") end
    local log = vim.fn.systemlist("git log --oneline -100 -- " .. git_file())
    if #log == 0 then return print("No history") end
    local qf = {}
    for _, line in ipairs(log) do
      local hash = line:match("^(%w+)")
      if hash then table.insert(qf, { text = line, user_data = hash }) end
    end
    vim.fn.setqflist(qf, "r")
    vim.fn.setqflist({}, "a", { title = "Git Log: " .. rel })
    vim.cmd("copen")
    local function qf_enter()
      local item = vim.fn.getqflist()[vim.fn.line(".")]
      if item and item.user_data then
        local diff = vim.fn.systemlist("git show " .. item.user_data .. " -- " .. rel)
        if #diff > 0 then scratch(diff, "git") end
      end
    end
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.api.nvim_buf_get_option(buf, "filetype") == "qf" then map("n", "<CR>", qf_enter, { buffer = buf }) end
    end
    vim.api.nvim_create_autocmd("FileType", { pattern = "qf", once = true, callback = function(ev) map("n", "<CR>", qf_enter, { buffer = ev.buf }) end })
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


-- Keymaps: navigation, buffer, clipboard, quickfix, replace, etc.
map("n", "<Esc>", "<cmd>noh<cr>")
map("n", "<leader>w", "<cmd>w<cr>")
map("n", "<leader>q", "<cmd>q<cr>")
map("n", "<leader>Q", "<cmd>qa<cr>")
map("n", "Q", function()
  for _, win in ipairs(vim.fn.getwininfo()) do if win.quickfix == 1 then vim.cmd("cclose"); return end end
  if vim.fn.empty(vim.fn.getqflist()) == 1 then print("Quickfix empty") else vim.cmd("copen") end
end)
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
map("n", "<leader>c", function() vim.cmd("e " .. vim.fn.stdpath("config") .. "/init_minimal.lua") end)

-- Replace word under cursor or visual selection
map("n", "<leader>r", function()
  local word = vim.fn.expand("<cword>")
  vim.fn.feedkeys(":%s/\\<" .. word .. "\\>/" .. word .. "/gc", "n")
  vim.fn.feedkeys(string.rep("\b", #word + 3), "n")
end)
map("v", "<leader>r", function()
  vim.cmd('normal! "zy')
  local selection = vim.fn.getreg("z")
  local escaped = vim.fn.escape(selection, "\\/")
  vim.fn.feedkeys(":%s/\\V" .. escaped .. "/" .. selection .. "/gc", "n")
  vim.fn.feedkeys(string.rep("\b", #selection + 3), "n")
end)

-- Run file
map("n", "<leader>R", function()
  local file = vim.fn.shellescape(vim.fn.expand("%:p"))
  local cmds = { python = "python3 " .. file, sh = "bash " .. file, bash = "bash " .. file, lua = "lua " .. file, c = "gcc " .. file .. " -o /tmp/a.out && /tmp/a.out", rust = "cargo run" }
  local cmd = cmds[vim.bo.filetype]
  if cmd then vim.cmd("terminal " .. cmd) else print("No run command for: " .. vim.bo.filetype) end
end)


-- Utilities
map("n", "<leader>sw", function()
  local v = vim.fn.winsaveview(); vim.cmd([[%s/\s\+$//e]]); vim.fn.winrestview(v); print("Stripped whitespace")
end)
map("n", "<leader>st", function()
  local n = tonumber(vim.fn.input("Tab width: ")); if n then vim.bo.tabstop, vim.bo.shiftwidth = n, n end
end)
map("n", "<leader>bo", function()
  local visible, closed = {}, 0
  for _, w in ipairs(vim.api.nvim_list_wins()) do visible[vim.api.nvim_win_get_buf(w)] = true end
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(b) and not visible[b] and vim.bo[b].buftype == "" then pcall(vim.api.nvim_buf_delete, b, {}); closed = closed + 1 end
  end
  print("Closed " .. closed .. " hidden buffers")
end)


-- Autocommands
vim.api.nvim_create_autocmd("TextYankPost", { callback = function() vim.highlight.on_yank() end })
vim.api.nvim_create_autocmd("BufReadPost", { callback = function()
  local m = vim.api.nvim_buf_get_mark(0, '"')
  if m[1] > 0 and m[1] <= vim.api.nvim_buf_line_count(0) then pcall(vim.api.nvim_win_set_cursor, 0, m) end
end })
vim.api.nvim_create_autocmd("TermClose", { callback = function() vim.cmd("bd!") end })
vim.api.nvim_create_autocmd("FileType", { pattern = "qf", callback = function() map("n", "q", "<cmd>cclose<cr>", { buffer = true }) end })


-- Help
map("n", "<leader>?", function()
  print([[
CUSTOM:   w/q/Q save/quit/toggle-qf | ff/fr/fb/fg find | e/- explore | y/p clip | bd/bo buf | Tab nav | C-hjkl win
          r replace word/selection | R run | c config | F2 auto-cmp | F3 numbers
GIT:      gd diff/merge gD diff(tab) gi diff(inline) | gs/gC/gP status/commit/push | ga/gu stage/unstage
          gb blame | gl log(qf+Enter=diff) | gL global-log | gr/gR reset-file (index/HEAD)
HUNK:     hp preview | ha/hu stage/unstage | hr/hR reset (index/HEAD) | ]c/[c nav
CONFLICT: gH/gJ/gL resolve block (ours/base/theirs) | MISC: sw strip | st tab
NATIVE:   gd/gD/grr/gri/K/grn/gra LSP | [d/]d [e/]e diag | gc comment | <C-L> clear | ZZ quit]])
end)
