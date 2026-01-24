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
local auto_cmp, auto_cmp_group = false, vim.api.nvim_create_augroup("AutoCmp", { clear = true })
map("n", "<F2>", function()
  auto_cmp = not auto_cmp
  vim.api.nvim_clear_autocmds { group = auto_cmp_group }
  if auto_cmp then
    vim.api.nvim_create_autocmd("TextChangedI", { group = auto_cmp_group, callback = function()
      if vim.fn.pumvisible() == 1 or vim.fn.col(".") < 3 then return end
      local char = vim.fn.getline("."):sub(vim.fn.col(".") - 1, vim.fn.col(".") - 1)
      if char:match("[%w_%.%-]") then
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(vim.bo.omnifunc ~= "" and "<C-x><C-o>" or "<C-n>", true, false, true), "n", false)
      end
    end })
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

-- ══════════════════════════════════════════════════════════════════════════════
-- GIT: State & Configuration
-- ══════════════════════════════════════════════════════════════════════════════
if vim.fn.executable("git") == 1 then
  -- Namespaces
  local git_ns = vim.api.nvim_create_namespace("git_gutter")
  local inline_ns = vim.api.nvim_create_namespace("inline_diff")

  -- Configuration state
  local git_diff_mode = "all"  -- "all" (git diff HEAD) or "unstaged" (git diff)
  local show_hunk_hints = false

  -- Per-buffer caches
  local buf_git_cache = {}   -- { [buf] = { name, rel, file } }
  local content_cache = {}   -- { [buf] = { index, head, ts } }
  local inline_on = {}
  local debounce_timers = {}
  local diff_state = {}      -- { [work_buf] = { ref_buf, ref_win } }

  -- ══════════════════════════════════════════════════════════════════════════════
  -- GIT: Helpers
  -- ══════════════════════════════════════════════════════════════════════════════

  -- Execute git command, return result or nil on error
  local function git_cmd(cmd, input)
    local result = input and vim.fn.system(cmd, input) or vim.fn.system(cmd)
    return vim.v.shell_error == 0 and result or nil
  end

  local function git_cmd_lines(cmd)
    local lines = vim.fn.systemlist(cmd)
    return vim.v.shell_error == 0 and lines or {}
  end

  -- Fetch content at a git reference (HEAD, :0:, :2:, :3:, or commit hash)
  local function git_show(ref, rel)
    return git_cmd_lines("git show " .. ref .. ":" .. rel)
  end

  local function git_show_str(ref, rel)
    return git_cmd("git show " .. ref .. ":" .. rel)
  end

  -- Apply a patch with options
  local function git_apply(patch, opts)
    opts = opts or {}
    local cmd = "git apply"
    if opts.cached then cmd = cmd .. " --cached" end
    if opts.reverse then cmd = cmd .. " --reverse" end
    cmd = cmd .. " --unidiff-zero -"
    return git_cmd(cmd, patch) ~= nil
  end

  -- Per-buffer git path caching
  local function get_buf_git_info(buf)
    buf = buf or vim.api.nvim_get_current_buf()
    local name = vim.api.nvim_buf_get_name(buf)
    if name == "" then return nil end

    local cached = buf_git_cache[buf]
    if cached and cached.name == name then
      return cached
    end

    local lines = git_cmd_lines("git ls-files --full-name " .. vim.fn.shellescape(name))
    local rel = lines[1]
    if not rel or rel == "" then
      buf_git_cache[buf] = nil
      return nil
    end

    buf_git_cache[buf] = {
      name = name,
      rel = rel,
      file = vim.fn.shellescape(name),
    }
    return buf_git_cache[buf]
  end

  local function git_file(buf)
    local info = get_buf_git_info(buf)
    return info and info.file or vim.fn.shellescape(vim.api.nvim_buf_get_name(buf or 0))
  end

  local function git_rel(buf)
    local info = get_buf_git_info(buf)
    return info and info.rel or nil
  end

  -- Forward declarations for refresh_buf (defined after update functions)
  local refresh_content_cache, update_signs, update_inline_diff, update_diff_split

  -- Refresh all git state for a buffer
  local function refresh_buf(buf, opts)
    buf = buf or vim.api.nvim_get_current_buf()
    opts = opts or {}
    if opts.reload then vim.cmd("e!") end
    refresh_content_cache(buf)
    update_signs(buf)
    if inline_on[buf] then update_inline_diff(buf) end
    update_diff_split(buf)
  end

  -- ══════════════════════════════════════════════════════════════════════════════
  -- GIT: Diff Window Management
  -- ══════════════════════════════════════════════════════════════════════════════

  -- Unified diff window management
  local function close_diff()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.api.nvim_buf_is_valid(buf) and vim.b[buf].is_diff then
        pcall(vim.api.nvim_win_close, win, false)
      end
    end
    vim.cmd("diffoff!")
    diff_state = {}  -- Clear diff tracking
  end

  local function make_diff_buf(lines, ft)
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
    vim.bo.buftype, vim.bo.bufhidden, vim.b.is_diff, vim.bo.modifiable = "nofile", "wipe", true, false
    vim.bo.filetype = ft or "diff"
    map("n", "q", close_diff, { buffer = true })
  end

  local function diff_tab(lines, ft)
    vim.cmd("tabnew")
    make_diff_buf(lines, ft)
  end

  local function diff_split(lines, ft)
    vim.cmd("vnew")
    make_diff_buf(lines, ft)
    vim.cmd("diffthis")
    vim.wo.foldcolumn = "0"
  end

  -- Update diff split with new reference content
  update_diff_split = function(work_buf)
    local state = diff_state[work_buf]
    if not state then return end

    if not vim.api.nvim_win_is_valid(state.ref_win) or not vim.api.nvim_buf_is_valid(state.ref_buf) then
      diff_state[work_buf] = nil
      return
    end

    local rel = git_rel()
    if not rel then return end

    local ref = git_diff_mode == "all" and "HEAD" or ":0"
    local base = git_show(ref, rel)
    if #base == 0 then return end

    local current_win = vim.api.nvim_get_current_win()

    vim.api.nvim_buf_set_option(state.ref_buf, "modifiable", true)
    vim.api.nvim_buf_set_lines(state.ref_buf, 0, -1, false, base)
    vim.api.nvim_buf_set_option(state.ref_buf, "modifiable", false)

    vim.schedule(function()
      if not vim.api.nvim_win_is_valid(state.ref_win) then return end

      vim.api.nvim_set_current_win(state.ref_win)
      vim.cmd("diffoff! | diffthis")

      local work_wins = vim.fn.win_findbuf(work_buf)
      if #work_wins > 0 then
        vim.api.nvim_set_current_win(work_wins[1])
        vim.cmd("diffoff! | diffthis")
      end

      if vim.api.nvim_win_is_valid(current_win) then
        vim.api.nvim_set_current_win(current_win)
      end
    end)
  end

  -- Unified git/diff color scheme (GitHub/Claude Code style)
  local function set_git_highlights()
    -- Unstaged changes (bright, prominent)
    vim.api.nvim_set_hl(0, "GitSignAdd", { fg = "#2ea043", bold = true })
    vim.api.nvim_set_hl(0, "GitSignChange", { fg = "#d29922", bold = true })
    vim.api.nvim_set_hl(0, "GitSignDelete", { fg = "#f85149", bold = true })

    -- Staged changes (dimmer, same colors but less bold)
    vim.api.nvim_set_hl(0, "GitSignAddStaged", { fg = "#1d6f2e" })
    vim.api.nvim_set_hl(0, "GitSignChangeStaged", { fg = "#8a6616" })
    vim.api.nvim_set_hl(0, "GitSignDeleteStaged", { fg = "#a03232" })

    -- Both staged and unstaged (split indicator)
    vim.api.nvim_set_hl(0, "GitSignAddBoth", { fg = "#2ea043", bg = "#1d6f2e" })
    vim.api.nvim_set_hl(0, "GitSignChangeBoth", { fg = "#d29922", bg = "#8a6616" })
    vim.api.nvim_set_hl(0, "GitSignDeleteBoth", { fg = "#f85149", bg = "#a03232" })

    -- Line backgrounds (for inline diff and split views)
    vim.api.nvim_set_hl(0, "GitLineAdd", { bg = "#1d3b2a" })
    vim.api.nvim_set_hl(0, "GitLineChange", { bg = "#3b3520" })
    vim.api.nvim_set_hl(0, "GitLineDelete", { bg = "#3b1d1d" })

    -- Native diff mode (gd split view)
    vim.api.nvim_set_hl(0, "DiffAdd", { bg = "#1d3b2a" })
    vim.api.nvim_set_hl(0, "DiffChange", { bg = "#2a2a20" })
    vim.api.nvim_set_hl(0, "DiffDelete", { bg = "#3b1d1d", fg = "#5c3030" })
    vim.api.nvim_set_hl(0, "DiffText", { bg = "#3b3520", bold = true })
  end

  set_git_highlights()
  vim.api.nvim_create_autocmd("ColorScheme", { callback = set_git_highlights })

  -- ══════════════════════════════════════════════════════════════════════════════
  -- GIT: Content Cache (Index + HEAD)
  -- ══════════════════════════════════════════════════════════════════════════════

  refresh_content_cache = function(buf)
    local name = vim.api.nvim_buf_get_name(buf)
    if vim.bo[buf].buftype ~= "" or name == "" then
      content_cache[buf] = nil
      return
    end

    local rel = git_rel(buf)
    if not rel then
      content_cache[buf] = nil
      return
    end

    content_cache[buf] = {
      index = git_show_str(":0", rel),
      head = git_show_str("HEAD", rel),
    }
  end

  -- ══════════════════════════════════════════════════════════════════════════════
  -- GIT: Gutter Signs
  -- ══════════════════════════════════════════════════════════════════════════════

  -- Convert diff hunks to line map { [lnum] = "add"|"change"|"delete" }
  local function hunks_to_lines(hunks, max_lines)
    local lines = {}
    for _, hunk in ipairs(hunks) do
      local old_count, new_start, new_count = hunk[2], hunk[3], hunk[4]
      local change_type = (old_count == 0 and new_count > 0) and "add" or
                         (new_count == 0 and old_count > 0) and "delete" or "change"
      if new_count > 0 then
        for l = new_start, new_start + new_count - 1 do
          lines[l] = change_type
        end
      else
        lines[math.max(1, math.min(new_start, max_lines))] = "delete"
      end
    end
    return lines
  end

  -- Get sign text and highlight for a line's git state
  local function get_sign_for_line(unstaged, staged)
    if unstaged and staged then
      local t = unstaged == "delete" and "━" or "║"
      local hl = unstaged == "add" and "GitSignAddBoth" or
                 unstaged == "change" and "GitSignChangeBoth" or "GitSignDeleteBoth"
      return t, hl
    elseif unstaged then
      local t = unstaged == "add" and "│" or unstaged == "change" and "│" or "▁"
      local hl = unstaged == "add" and "GitSignAdd" or
                 unstaged == "change" and "GitSignChange" or "GitSignDelete"
      return t, hl
    else
      local t = staged == "add" and "┃" or staged == "change" and "┃" or "▔"
      local hl = staged == "add" and "GitSignAddStaged" or
                 staged == "change" and "GitSignChangeStaged" or "GitSignDeleteStaged"
      return t, hl
    end
  end

  update_signs = function(buf)
    local cache = content_cache[buf]
    if not vim.api.nvim_buf_is_valid(buf) or not cache then return end
    if not cache.head or not cache.index then return end

    vim.api.nvim_buf_clear_namespace(buf, git_ns, 0, -1)

    local buf_content = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n") .. "\n"
    local buf_line_count = vim.api.nvim_buf_line_count(buf)

    -- Unstaged changes: INDEX vs working tree (working tree line numbers)
    local unstaged_hunks = vim.diff(cache.index, buf_content, { result_type = "indices" })
    local unstaged_lines = hunks_to_lines(unstaged_hunks, buf_line_count)

    -- Staged changes: HEAD vs INDEX (index line numbers)
    local staged_hunks = vim.diff(cache.head, cache.index, { result_type = "indices" })
    local index_line_count = select(2, cache.index:gsub("\n", "\n")) + 1
    local staged_in_index = hunks_to_lines(staged_hunks, index_line_count)

    -- Map staged changes from INDEX line space to working tree line space
    local staged_lines = {}
    for index_lnum, change_type in pairs(staged_in_index) do
      -- Calculate offset: sum of (new_count - old_count) for all hunks ending before this line
      local offset = 0
      for _, h in ipairs(unstaged_hunks) do
        local old_start, old_count, new_count = h[1], h[2], h[4]
        local old_end = old_start + math.max(0, old_count - 1)
        if old_end < index_lnum then
          -- Hunk ends before this line, apply full offset
          offset = offset + (new_count - old_count)
        elseif old_start <= index_lnum and index_lnum <= old_end then
          -- We're inside this hunk - line may have moved or been deleted
          -- Map proportionally within the hunk
          local pos_in_hunk = index_lnum - old_start
          if new_count > 0 then
            offset = offset + pos_in_hunk  -- Approximate position in new
          end
          break
        end
      end
      local working_lnum = index_lnum + offset
      if working_lnum >= 1 and working_lnum <= buf_line_count then
        staged_lines[working_lnum] = change_type
      end
    end

    -- Build display lines based on mode
    local display_lines = {}
    if git_diff_mode == "all" then
      for l in pairs(unstaged_lines) do display_lines[l] = true end
      for l in pairs(staged_lines) do display_lines[l] = true end
    else
      for l in pairs(unstaged_lines) do display_lines[l] = true end
    end

    -- Place extmarks
    for lnum in pairs(display_lines) do
      local sign_text, sign_hl = get_sign_for_line(unstaged_lines[lnum], staged_lines[lnum])
      pcall(vim.api.nvim_buf_set_extmark, buf, git_ns, lnum - 1, 0, {
        sign_text = sign_text, sign_hl_group = sign_hl, priority = 10,
      })
    end

    -- Add virtual text hints for hunk boundaries
    if show_hunk_hints then
      local prev_lnum = 0
      local sorted_lines = {}
      for l in pairs(display_lines) do table.insert(sorted_lines, l) end
      table.sort(sorted_lines)

      for _, lnum in ipairs(sorted_lines) do
        -- Check if this is the start of a new hunk (gap > 1 from previous)
        if lnum > prev_lnum + 1 or prev_lnum == 0 then
          -- Count consecutive lines in this hunk
          local hunk_size = 1
          for i = lnum + 1, vim.api.nvim_buf_line_count(buf) do
            if display_lines[i] then
              hunk_size = hunk_size + 1
            else
              break
            end
          end

          -- Add virtual text on first line of hunk
          local unstaged = unstaged_lines[lnum]
          local staged = staged_lines[lnum]
          local virt_text = ""

          if unstaged and staged then
            virt_text = string.format("  [%d lines • staged + unstaged]", hunk_size)
          elseif unstaged then
            virt_text = string.format("  [%d lines • unstaged]", hunk_size)
          else
            virt_text = string.format("  [%d lines • staged]", hunk_size)
          end

          pcall(vim.api.nvim_buf_set_extmark, buf, git_ns, lnum - 1, 0, {
            virt_text = { { virt_text, "Comment" } },
            virt_text_pos = "eol",
            priority = 1,
          })
        end
        prev_lnum = lnum
      end
    end
  end

  -- Toggle hunk hints
  map("n", "<leader>gh", function()
    show_hunk_hints = not show_hunk_hints
    local buf = vim.api.nvim_get_current_buf()
    update_signs(buf)
    print("Hunk hints: " .. (show_hunk_hints and "ON" or "OFF"))
  end)

  -- Toggle git diff mode
  map("n", "<leader>gm", function()
    git_diff_mode = git_diff_mode == "all" and "unstaged" or "all"
    local mode_names = { all = "All changes (git diff HEAD)", unstaged = "Unstaged only (git diff)" }

    local buf = vim.api.nvim_get_current_buf()
    update_signs(buf)
    if inline_on[buf] then update_inline_diff(buf) end

    -- Update all active diff splits (not just current buffer)
    for work_buf, _ in pairs(diff_state) do
      update_diff_split(work_buf)
    end

    print("Git diff mode: " .. mode_names[git_diff_mode])
  end)

  local function debounced_update(buf, delay)
    if debounce_timers[buf] then vim.fn.timer_stop(debounce_timers[buf]) end
    debounce_timers[buf] = vim.fn.timer_start(delay, function()
      debounce_timers[buf] = nil
      vim.schedule(function()
        update_signs(buf)
        if inline_on[buf] then update_inline_diff(buf) end
      end)
    end)
  end

  -- ══════════════════════════════════════════════════════════════════════════════
  -- GIT: Autocmds
  -- ══════════════════════════════════════════════════════════════════════════════

  vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "FocusGained" }, { callback = function(ev)
    refresh_content_cache(ev.buf)
    update_signs(ev.buf)
    if inline_on[ev.buf] then update_inline_diff(ev.buf) end
  end })
  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, { callback = function(ev) debounced_update(ev.buf, 150) end })
  vim.api.nvim_create_autocmd("BufDelete", { callback = function(ev)
    content_cache[ev.buf] = nil
    buf_git_cache[ev.buf] = nil
    inline_on[ev.buf] = nil
    diff_state[ev.buf] = nil
    if debounce_timers[ev.buf] then vim.fn.timer_stop(debounce_timers[ev.buf]); debounce_timers[ev.buf] = nil end
  end })

  -- ══════════════════════════════════════════════════════════════════════════════
  -- GIT: Hunk Operations
  -- ══════════════════════════════════════════════════════════════════════════════

  local function get_hunks(staged)
    local rel = git_rel()
    if not rel then return {} end

    -- Build diff command based on mode or explicit staged parameter
    local diff_cmd = staged ~= nil
      and (staged and "git diff --cached -U0 -- " or "git diff -U0 -- ")
      or (git_diff_mode == "all" and "git diff HEAD -U0 -- " or "git diff -U0 -- ")

    local diff = git_cmd_lines(diff_cmd .. git_file())
    local hunks = {}

    for i, line in ipairs(diff) do
      local os, oc, ns, nc = line:match("^@@%s*%-(%d+),?(%d*)%s*%+(%d+),?(%d*)%s*@@")
      if ns then
        local hunk_lines = { line }
        for j = i + 1, #diff do
          if diff[j]:match("^@@") then break end
          table.insert(hunk_lines, diff[j])
        end
        table.insert(hunks, {
          start = tonumber(ns), count = tonumber(nc ~= "" and nc or 1),
          old_start = tonumber(os), old_count = tonumber(oc ~= "" and oc or 1),
          lines = hunk_lines, rel = rel,
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

  -- Enhanced hunk preview with context and stats
  map("n", "<leader>hp", function()
    local h = hunk_at_cursor()
    if not h then return print("No hunk") end

    -- Calculate stats
    local adds, dels = 0, 0
    for _, line in ipairs(h.lines) do
      if line:match("^%+") and not line:match("^%+%+%+") then adds = adds + 1
      elseif line:match("^%-") and not line:match("^%-%-%-") then dels = dels + 1
      end
    end

    -- Show preview with header
    local preview = { "# Hunk Preview: +" .. adds .. " -" .. dels, "" }
    for _, line in ipairs(h.lines) do
      table.insert(preview, line)
    end

    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_open_win(buf, true, {
      relative = "cursor", row = 1, col = 0,
      width = math.min(80, vim.o.columns - 4),
      height = math.min(#preview + 2, 20),
      style = "minimal", border = "rounded",
      title = " Hunk Actions: ha=stage | hu=unstage | hr=reset ",
      title_pos = "center"
    })
    make_diff_buf(preview, "diff")
  end)

  -- Unified hunk operation helper
  local function hunk_op(staged, opts, msg)
    local h = staged == nil and (hunk_at_cursor(true) or hunk_at_cursor(false)) or hunk_at_cursor(staged)
    if not h then return print("No hunk") end
    if git_apply(make_patch(h, false), opts) then
      refresh_buf(nil, { reload = opts.reload })
      print(msg)
    else
      print("Failed")
    end
  end

  map("n", "<leader>ha", function() hunk_op(false, { cached = true }, "Staged hunk") end)
  map("n", "<leader>hu", function() hunk_op(true, { cached = true, reverse = true }, "Unstaged hunk") end)
  map("n", "<leader>hr", function() hunk_op(false, { reverse = true, reload = true }, "Reset hunk to index") end)

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

  -- ══════════════════════════════════════════════════════════════════════════════
  -- GIT: Inline Diff
  -- ══════════════════════════════════════════════════════════════════════════════

  function update_inline_diff(buf)
    vim.api.nvim_buf_clear_namespace(buf, inline_ns, 0, -1)

    local cache = content_cache[buf]
    if not cache then return end

    -- Get base content based on mode (same as gd)
    local base = git_diff_mode == "all" and cache.head or cache.index
    if not base then return end

    local buf_content = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n") .. "\n"
    local diff = vim.diff(base, buf_content, { result_type = "unified" })
    if not diff or diff == "" then return end

    local diff_lines = vim.split(diff, "\n")
    local i = 1

    while i <= #diff_lines do
      local line = diff_lines[i]
      local old_start, old_count, new_start, new_count = line:match("^@@%s*%-(%d+),?(%d*)%s*%+(%d+),?(%d*)%s*@@")

      if old_start then
        old_start = tonumber(old_start)
        old_count = tonumber(old_count ~= "" and old_count or 1)
        new_start = tonumber(new_start)
        new_count = tonumber(new_count ~= "" and new_count or 1)

        local deleted_lines = {}
        i = i + 1

        while i <= #diff_lines and not diff_lines[i]:match("^@@") do
          local dl = diff_lines[i]
          if dl:match("^%-") and not dl:match("^%-%-%-") then
            table.insert(deleted_lines, dl:sub(2))
          end
          i = i + 1
        end

        -- Show deleted lines as virtual text
        if #deleted_lines > 0 then
          local virt_lines = {}
          for _, dline in ipairs(deleted_lines) do
            table.insert(virt_lines, { { "  - " .. dline, "DiffDelete" } })
          end
          local mark_line = math.max(0, new_start - 1)
          pcall(vim.api.nvim_buf_set_extmark, buf, inline_ns, mark_line, 0, {
            virt_lines = virt_lines,
            virt_lines_above = true,
          })
        end

        -- Highlight changed/added lines (no sign_text to preserve gutter)
        if new_count > 0 then
          local hl_group = old_count == 0 and "DiffAdd" or "DiffChange"
          for l = new_start, new_start + new_count - 1 do
            pcall(vim.api.nvim_buf_set_extmark, buf, inline_ns, l - 1, 0, {
              line_hl_group = hl_group,
              priority = 5,  -- Lower than gutter (10)
            })
          end
        elseif #deleted_lines > 0 then
          -- Pure deletion marker
          local mark_line = math.max(0, math.min(new_start, vim.api.nvim_buf_line_count(buf) - 1))
          pcall(vim.api.nvim_buf_set_extmark, buf, inline_ns, mark_line, 0, {
            line_hl_group = "DiffDelete",
            priority = 5,
          })
        end
      else
        i = i + 1
      end
    end
  end

  map("n", "gi", function()
    local buf = vim.api.nvim_get_current_buf()

    if inline_on[buf] then
      inline_on[buf] = false
      vim.api.nvim_buf_clear_namespace(buf, inline_ns, 0, -1)
      print("Inline diff: OFF")
    else
      inline_on[buf] = true
      update_inline_diff(buf)
      local mode_label = git_diff_mode == "all" and "vs HEAD" or "vs INDEX"
      print("Inline diff: ON (" .. mode_label .. ") - gi/q=off")
      vim.keymap.set("n", "q", function()
        inline_on[buf] = false
        vim.api.nvim_buf_clear_namespace(buf, inline_ns, 0, -1)
        print("Inline diff: OFF")
      end, { buffer = buf })
    end
  end)

  -- ══════════════════════════════════════════════════════════════════════════════
  -- GIT: Conflict Resolution
  -- ══════════════════════════════════════════════════════════════════════════════

  -- Enhanced conflict resolution with preview
  local function resolve_conflict(buf, choice)
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local cur = vim.api.nvim_win_get_cursor(0)[1]
    local s, m, e, f

    -- Find conflict markers
    for i = cur, 1, -1 do
      if lines[i]:match("^<<<<<<<") then s = i; break end
    end
    if not s then return print("Not in conflict") end

    for i = s, #lines do
      if lines[i]:match("^|||||||") then m = i
      elseif lines[i]:match("^=======") then e = i
      elseif lines[i]:match("^>>>>>>>") then f = i; break end
    end
    if not e or not f then return print("Malformed conflict") end

    local ranges = {
      ours = { s + 1, (m or e) - 1 },
      theirs = { e + 1, f - 1 },
      base = m and { m + 1, e - 1 }
    }
    local range = ranges[choice]
    if not range then return print("No base section") end

    local result = {}
    for i = range[1], range[2] do
      table.insert(result, lines[i])
    end

    vim.api.nvim_buf_set_lines(buf, s - 1, f, false, result)
    print("Resolved with " .. choice .. " (" .. #result .. " lines)")
  end

  -- Preview conflict choices
  map("n", "<leader>gp", function()
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local cur = vim.api.nvim_win_get_cursor(0)[1]
    local s, m, e, f

    for i = cur, 1, -1 do
      if lines[i]:match("^<<<<<<<") then s = i; break end
    end
    if not s then return print("Not in conflict") end

    for i = s, #lines do
      if lines[i]:match("^|||||||") then m = i
      elseif lines[i]:match("^=======") then e = i
      elseif lines[i]:match("^>>>>>>>") then f = i; break end
    end
    if not e or not f then return print("Malformed conflict") end

    local preview = { "=== CONFLICT PREVIEW ===" }
    table.insert(preview, "")
    table.insert(preview, "OURS (gH):")
    for i = s + 1, (m or e) - 1 do
      table.insert(preview, "  " .. lines[i])
    end

    if m then
      table.insert(preview, "")
      table.insert(preview, "BASE (gJ):")
      for i = m + 1, e - 1 do
        table.insert(preview, "  " .. lines[i])
      end
    end

    table.insert(preview, "")
    table.insert(preview, "THEIRS (gL):")
    for i = e + 1, f - 1 do
      table.insert(preview, "  " .. lines[i])
    end

    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_open_win(buf, true, {
      relative = "cursor", row = 1, col = 0,
      width = math.min(80, vim.o.columns - 4),
      height = math.min(#preview + 2, 25),
      style = "minimal", border = "rounded",
      title = " Conflict Resolution Options ",
      title_pos = "center"
    })
    make_diff_buf(preview, "diff")
  end)

  -- ══════════════════════════════════════════════════════════════════════════════
  -- GIT: Diff Commands
  -- ══════════════════════════════════════════════════════════════════════════════

  map("n", "<leader>gd", function()
    local rel = git_rel()
    if not rel then return print("Not tracked") end

    -- Check for merge conflict (3-way merge)
    local ours, theirs = git_show(":2", rel), git_show(":3", rel)
    if #ours > 0 and #theirs > 0 then
      vim.cmd("tabnew " .. vim.fn.fnameescape(vim.api.nvim_buf_get_name(0)))
      local work_buf = vim.api.nvim_get_current_buf()
      vim.cmd("diffthis")

      vim.cmd("leftabove vnew")
      make_diff_buf(ours, vim.bo[work_buf].filetype)
      vim.cmd("diffthis"); vim.wo.foldcolumn = "0"
      local ours_buf = vim.api.nvim_get_current_buf()

      vim.cmd("wincmd l | rightbelow vnew")
      make_diff_buf(theirs, vim.bo[work_buf].filetype)
      vim.cmd("diffthis"); vim.wo.foldcolumn = "0"
      local theirs_buf = vim.api.nvim_get_current_buf()

      vim.api.nvim_set_current_win(vim.fn.win_findbuf(work_buf)[1])
      map("n", "gh", "<cmd>diffget " .. ours_buf .. "<cr>", { buffer = work_buf })
      map("n", "gl", "<cmd>diffget " .. theirs_buf .. "<cr>", { buffer = work_buf })
      map("n", "q", "<cmd>tabclose<cr>", { buffer = work_buf })
      return print("3-way merge: OURS | WORKING | THEIRS (gh/gl=hunk gH/gJ/gL=block ]c/[c=nav q=quit)")
    end

    -- Normal diff based on mode
    local ref = git_diff_mode == "all" and "HEAD" or ":0"
    local label = git_diff_mode == "all" and "HEAD" or "INDEX"
    local base = git_show(ref, rel)
    if #base == 0 then return print("No " .. label) end

    local work_buf = vim.api.nvim_get_current_buf()
    diff_split(base, vim.bo.filetype)
    diff_state[work_buf] = { ref_buf = vim.api.nvim_get_current_buf(), ref_win = vim.api.nvim_get_current_win() }
    vim.cmd("wincmd p | diffthis")
    map("n", "q", close_diff, { buffer = work_buf })
    print("Diff: " .. label .. " | CURRENT - ]c/[c=nav q=quit")
  end)

  map("n", "<leader>gD", function()
    local rel = git_rel()
    if not rel then return print("Not tracked") end

    local cmd = git_diff_mode == "all" and "git diff HEAD -- " or "git diff -- "
    local diff = git_cmd_lines(cmd .. git_file())
    if #diff == 0 then return print("No changes") end

    diff_tab(diff, "diff")
    print("Unified diff (" .. (git_diff_mode == "all" and "all changes" or "unstaged only") .. ") - q=quit")
  end)

  -- ══════════════════════════════════════════════════════════════════════════════
  -- GIT: File Operations
  -- ══════════════════════════════════════════════════════════════════════════════

  local function git_file_op(cmd, msg, reload)
    if not git_cmd(cmd .. " " .. git_file()) then return print("Failed") end
    refresh_buf(nil, { reload = reload })
    print(msg)
  end

  -- Git status with interactive file navigation
  local function get_status_text(code)
    if code:match("M") then return "[Modified]"
    elseif code:match("A") then return "[Added]"
    elseif code:match("D") then return "[Deleted]"
    elseif code:match("R") then return "[Renamed]"
    elseif code:match("?") then return "[Untracked]"
    else return "[Changed]" end
  end

  map("n", "<leader>gs", function()
    local status = git_cmd_lines("git status --porcelain")
    if #status == 0 then return print("No changes") end

    local qf = {}
    for _, line in ipairs(status) do
      local code, file = line:sub(1, 2), line:sub(4)
      table.insert(qf, { filename = file, lnum = 1, text = get_status_text(code) .. " " .. file })
    end

    vim.fn.setqflist(qf, "r")
    vim.fn.setqflist({}, "a", { title = "Git Status (Enter=open | ga=stage | gu=unstage)" })
    vim.cmd("copen")

    vim.api.nvim_create_autocmd("FileType", {
      pattern = "qf",
      once = true,
      callback = function(ev)
        map("n", "ga", function()
          local item = vim.fn.getqflist()[vim.fn.line(".")]
          if item and item.filename then
            git_cmd("git add " .. vim.fn.shellescape(item.filename))
            print("Staged: " .. item.filename)
          end
        end, { buffer = ev.buf })

        map("n", "gu", function()
          local item = vim.fn.getqflist()[vim.fn.line(".")]
          if item and item.filename then
            git_cmd("git restore --staged " .. vim.fn.shellescape(item.filename))
            print("Unstaged: " .. item.filename)
          end
        end, { buffer = ev.buf })
      end,
    })
  end)
  map("n", "<leader>ga", function() git_file_op("git add", "Staged", false) end)
  map("n", "<leader>gu", function() git_file_op("git restore --staged", "Unstaged", false) end)
  map("n", "<leader>gr", function() git_file_op("git restore", "Reset to index", true) end)

  map("n", "<leader>gb", function()
    local blame = git_cmd_lines("git blame --date=short " .. git_file())
    if #blame == 0 then return print("Not tracked") end
    diff_tab(blame, "git")
    print("Git blame (q=quit)")
  end)

  map("n", "<leader>gl", function()
    local rel = git_rel()
    if not rel then return print("Not tracked") end

    local log = git_cmd_lines("git log --oneline -100 -- " .. git_file())
    if #log == 0 then return print("No history") end

    local qf = {}
    for _, line in ipairs(log) do
      local hash = line:match("^(%w+)")
      if hash then table.insert(qf, { text = line, user_data = hash }) end
    end
    vim.fn.setqflist(qf, "r")
    vim.fn.setqflist({}, "a", { title = "Git Log: " .. rel })
    vim.cmd("copen")
    print("File history (Enter=show-commit q=close)")

    local function qf_enter()
      local item = vim.fn.getqflist()[vim.fn.line(".")]
      if item and item.user_data then
        local diff = git_cmd_lines("git show " .. item.user_data .. " -- " .. rel)
        if #diff > 0 then diff_tab(diff, "git") end
      end
    end
    vim.api.nvim_create_autocmd("FileType", { pattern = "qf", once = true, callback = function(ev)
      map("n", "<CR>", qf_enter, { buffer = ev.buf })
    end })
  end)

  map("n", "<leader>gL", function()
    local log = git_cmd_lines("git log --oneline -50")
    if #log == 0 then return print("No commits") end
    diff_tab(log, "git")
    print("Git log (q=quit)")
  end)

  -- Git summary view with current file status
  map("n", "<leader>gS", function()
    local summary = {}

    local branch = (git_cmd("git branch --show-current") or ""):gsub("\n", "")
    if branch ~= "" then table.insert(summary, "Branch: " .. branch) end

    local last_commit = (git_cmd("git log -1 --oneline") or ""):gsub("\n", "")
    if last_commit ~= "" then table.insert(summary, "Last commit: " .. last_commit) end

    table.insert(summary, "")
    table.insert(summary, "=== Current File ===")

    local rel = git_rel()
    if rel then
      table.insert(summary, "File: " .. rel)
      table.insert(summary, "Unstaged hunks: " .. #get_hunks(false))
      table.insert(summary, "Staged hunks: " .. #get_hunks(true))

      local status = (git_cmd("git status --porcelain " .. git_file()) or ""):gsub("\n", "")
      if status ~= "" then table.insert(summary, "Status: " .. status) end
    else
      table.insert(summary, "File: Not tracked")
    end

    table.insert(summary, "")
    table.insert(summary, "=== Repository Status ===")

    local status_lines = git_cmd_lines("git status --porcelain")
    local modified, added, deleted, untracked = 0, 0, 0, 0
    for _, line in ipairs(status_lines) do
      local code = line:sub(1, 2)
      if code:match("M") then modified = modified + 1
      elseif code:match("A") then added = added + 1
      elseif code:match("D") then deleted = deleted + 1
      elseif code:match("?") then untracked = untracked + 1
      end
    end

    table.insert(summary, "Modified: " .. modified)
    table.insert(summary, "Added: " .. added)
    table.insert(summary, "Deleted: " .. deleted)
    table.insert(summary, "Untracked: " .. untracked)

    diff_tab(summary, "git")
    print("Git summary (q=quit)")
  end)

  map("n", "<leader>gC", "<cmd>terminal git commit<cr>")
  map("n", "<leader>gP", "<cmd>!git push<cr>")

  -- Global conflict resolution (works anywhere in conflict blocks)
  map("n", "gH", function() resolve_conflict(0, "ours") end)
  map("n", "gJ", function() resolve_conflict(0, "base") end)
  map("n", "gL", function() resolve_conflict(0, "theirs") end)

  -- Navigate between changed files
  local changed_files_cache = nil
  local changed_files_index = 1

  local function refresh_changed_files()
    changed_files_cache = {}
    for _, line in ipairs(git_cmd_lines("git status --porcelain")) do
      table.insert(changed_files_cache, line:sub(4))
    end
  end

  map("n", "]f", function()
    if not changed_files_cache then refresh_changed_files() end
    if #changed_files_cache == 0 then return print("No changed files") end

    changed_files_index = changed_files_index + 1
    if changed_files_index > #changed_files_cache then changed_files_index = 1 end

    vim.cmd("e " .. vim.fn.fnameescape(changed_files_cache[changed_files_index]))
    print("File " .. changed_files_index .. "/" .. #changed_files_cache .. ": " .. changed_files_cache[changed_files_index])
  end)

  map("n", "[f", function()
    if not changed_files_cache then refresh_changed_files() end
    if #changed_files_cache == 0 then return print("No changed files") end

    changed_files_index = changed_files_index - 1
    if changed_files_index < 1 then changed_files_index = #changed_files_cache end

    vim.cmd("e " .. vim.fn.fnameescape(changed_files_cache[changed_files_index]))
    print("File " .. changed_files_index .. "/" .. #changed_files_cache .. ": " .. changed_files_cache[changed_files_index])
  end)

  -- Refresh cache on git operations
  vim.api.nvim_create_autocmd("BufWritePost", {
    callback = function() changed_files_cache = nil end
  })
end

local function nvim_tmux_nav(direction)
    local win = vim.api.nvim_get_current_win()
    vim.cmd('wincmd ' .. direction)
    -- If the window didn't change, we are at the edge; jump to Tmux
    if win == vim.api.nvim_get_current_win() then
        local tmux_dir = {h = 'L', j = 'D', k = 'U', l = 'R'}
        vim.fn.system('tmux select-pane -' .. tmux_dir[direction])
    end
end

vim.keymap.set('n', '<C-h>', function() nvim_tmux_nav('h') end)
vim.keymap.set('n', '<C-j>', function() nvim_tmux_nav('j') end)
vim.keymap.set('n', '<C-k>', function() nvim_tmux_nav('k') end)
vim.keymap.set('n', '<C-l>', function() nvim_tmux_nav('l') end)

-- Keymaps: navigation, buffer, clipboard, quickfix
map("n", "<Esc>", "<cmd>noh<cr>")
map("n", "<leader>w", "<cmd>w<cr>")
map("n", "<leader>q", "<cmd>q<cr>")
map("n", "<leader>Q", "<cmd>qa<cr>")
map("n", "Q", function()
  for _, win in ipairs(vim.fn.getwininfo()) do
    if win.quickfix == 1 then vim.cmd("cclose"); return end
  end
  if vim.fn.empty(vim.fn.getqflist()) == 1 then print("Quickfix empty") else vim.cmd("copen") end
end)
-- map("n", "<C-h>", "<C-w>h")
-- map("n", "<C-j>", "<C-w>j")
-- map("n", "<C-k>", "<C-w>k")
-- map("n", "<C-l>", "<C-w>l")
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
          r replace | R run | c config | F2 auto-cmp | F3 numbers | sw strip | st tab
GIT DIFF: gd split(2-way/3-way) | gD tab | gi inline-diff | gm mode(all/unstaged) | q=quit-diff
GIT NAV:  ]c/[c hunk | ]f/[f changed-file | ]e/[e errors | ]q/[q quickfix
GIT FILE: gs interactive-status(Enter ga/gu) | ga/gu stage/unstage | gr reset(soft)
GIT VIEW: gS summary | gh toggle-hints | gp conflict-preview | gC/gP commit/push
GIT HIST: gb blame | gl file-log(Enter=show) | gL repo-log
HUNK OPS: ha/hu stage/unstage-hunk | hr reset-hunk(soft)
CONFLICT: gH/gJ/gL resolve(ours/base/theirs) | gh/gl diffget(left/right) in 3-way | gp preview-options
LSP/DIAG: gd/gD/grr/gri/K/grn/gra LSP | gry/grf type/format

GIT GUTTER: Symbols: │=unstaged ┃=staged ║=both | Colors: green=add orange=change red=delete | gm=mode gi=inline]])
end)
