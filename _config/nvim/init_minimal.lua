-- Minimal Neovim Config - Plugin-Free & Portable
-- Python, Bash, Rust, Java, C/C++ | LSP, Git, Completion, Navigation

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
opt.showcmd, opt.cmdheight, opt.laststatus = true, 1, 2
opt.splitright, opt.splitbelow = true, true
opt.expandtab, opt.shiftwidth, opt.tabstop = true, 4, 4
opt.smartindent = true
opt.ignorecase, opt.smartcase = true, true
opt.incsearch, opt.hlsearch = true, true
opt.completeopt, opt.pumheight = "menu,menuone,noselect", 10
opt.shortmess:append("c")
opt.hidden, opt.autoread = true, true
opt.diffopt:append("vertical")
opt.list, opt.listchars = true, { tab = "│ ", trail = "·", extends = "→", precedes = "←", nbsp = "␣" }
opt.fillchars = { eob = " ", fold = " ", foldopen = "v", foldsep = " ", foldclose = ">" }

vim.o.statusline = " %f %m%r%h%w %= %y %{&ff} %l:%c %p%% "
pcall(vim.cmd, "colorscheme retrobox")

local map = vim.keymap.set

-- ============================================================================
-- LSP & DIAGNOSTICS (Neovim 0.11+ native)
-- ============================================================================
-- Install LSP servers:
--   Python:  pip install pyright
--   Bash:    npm install -g bash-language-server
--   Rust:    rustup component add rust-analyzer
--   Java:    https://github.com/eclipse-jdtls/eclipse.jdt.ls
--   C/C++:   Install clangd from package manager
--
-- Check status: <leader>li

local lsp_servers = { "bashls", "pyright", "jdtls", "rust_analyzer", "clangd" }

-- Enable servers that are installed
vim.lsp.enable(lsp_servers)

-- LSP keymaps on attach (using Neovim 0.11+ default keys)
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"

    local function m(mode, lhs, rhs, desc)
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

-- Diagnostics (using defaults)
map("n", "<C-W>d", vim.diagnostic.open_float, { desc = "Show diagnostic" })
map("n", "[d", vim.diagnostic.goto_prev, { desc = "Prev diagnostic" })
map("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
map("n", "[e", function() vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.ERROR }) end, { desc = "Prev error" })
map("n", "]e", function() vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.ERROR }) end, { desc = "Next error" })
-- map("n", "<leader>d", vim.diagnostic.open_float, { desc = "Show diagnostic" })

-- ============================================================================
-- COMPLETION
-- ============================================================================

-- Cache LSP client status per buffer to avoid repeated checks
local lsp_attached = {}
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev) lsp_attached[ev.buf] = true end,
})
vim.api.nvim_create_autocmd("LspDetach", {
  callback = function(ev) lsp_attached[ev.buf] = false end,
})
vim.api.nvim_create_autocmd("BufDelete", {
  callback = function(ev) lsp_attached[ev.buf] = nil end,
})

-- Helper: Check if LSP omnifunc is available (cached)
local function has_lsp_omnifunc()
  return lsp_attached[vim.api.nvim_get_current_buf()] and vim.bo.omnifunc ~= ""
end

-- Helper: Smart completion selection
local function smart_complete()
  local col = vim.fn.col('.') - 1
  local line = vim.fn.getline('.')
  local before = line:sub(1, col)

  -- File path completion
  if before:match('[~/.]?/?[%w._/-]*$') and (before:match('/') or before:match('^%.') or before:match('^~')) then
    return vim.api.nvim_replace_termcodes('<C-x><C-f>', true, false, true)
  end

  -- LSP omnifunc completion (with fallback)
  if has_lsp_omnifunc() and (before:match('[%w_][%w_]+$') or before:match('%.$') or before:match('->$') or before:match('::$')) then
    return vim.api.nvim_replace_termcodes('<C-x><C-o>', true, false, true)
  end

  -- Default to keyword completion (always works)
  return vim.api.nvim_replace_termcodes('<C-n>', true, false, true)
end

-- Tab: Smart completion with proper fallback
map("i", "<Tab>", function()
  -- If menu is visible, navigate down
  if vim.fn.pumvisible() == 1 then
    return "<C-n>"
  end

  -- At start of line or after whitespace: insert tab
  local col = vim.fn.col('.') - 1
  if col == 0 or vim.fn.getline('.'):sub(col, col):match('%s') then
    return "<Tab>"
  end

  -- Otherwise: smart completion
  return smart_complete()
end, { expr = true })

-- Shift-Tab: Navigate up in menu
map("i", "<S-Tab>", function()
  return vim.fn.pumvisible() == 1 and "<C-p>" or "<S-Tab>"
end, { expr = true })

-- Enter: Accept completion or insert newline
map("i", "<CR>", function()
  return vim.fn.pumvisible() == 1 and "<C-y>" or "<CR>"
end, { expr = true })

-- Note: Ctrl-N/Ctrl-P (keyword completion) and Ctrl-X submodes work by default, no mapping needed

-- Auto-complete on typing (optional, toggle with F2)
local auto_complete = false
local auto_complete_group = vim.api.nvim_create_augroup("AutoComplete", { clear = true })

map("n", "<F2>", function()
  auto_complete = not auto_complete
  if auto_complete then
    vim.api.nvim_create_autocmd("TextChangedI", {
      group = auto_complete_group,
      callback = function()
        vim.defer_fn(function()
          if vim.fn.pumvisible() == 0 and vim.fn.mode() == 'i' then
            local col = vim.fn.col('.')
            local before = vim.fn.getline('.'):sub(1, col - 1)

            -- Only trigger if typing meaningful content
            if before:match('[%w_][%w_]+$') or before:match('%.$') or before:match('->$') or before:match('::$') then
              -- Use safe completion with fallback
              if has_lsp_omnifunc() then
                pcall(function()
                  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-x><C-o>', true, false, true), 'n', false)
                end)
              else
                vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-n>', true, false, true), 'n', false)
              end
            end
          end
        end, 100)
      end,
    })
    print("Auto-completion: ON (LSP + keyword fallback)")
  else
    vim.api.nvim_clear_autocmds({ group = auto_complete_group })
    print("Auto-completion: OFF")
  end
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

-- Mappings
map("n", "<leader>sw", strip_whitespace, { desc = "Strip whitespace" })
map("n", "<leader>st", function() set_tab() end, { desc = "Set tab width" })
map("n", "<leader>bo", close_hidden_buffers, { desc = "Close hidden buffers" })

-- Commands
vim.api.nvim_create_user_command("StripWhitespace", strip_whitespace, { desc = "Strip trailing whitespace" })
vim.api.nvim_create_user_command("SetTab", function(opts)
  set_tab(opts.args ~= "" and tonumber(opts.args) or nil)
end, { nargs = "?", desc = "Set tab width" })
vim.api.nvim_create_user_command("CloseHiddenBuffers", close_hidden_buffers, { desc = "Close hidden buffers" })
vim.api.nvim_create_user_command("ToggleNumber", toggle_number, { desc = "Cycle number modes" })

-- ============================================================================
-- NAVIGATION
-- ============================================================================

vim.g.netrw_banner, vim.g.netrw_liststyle, vim.g.netrw_winsize = 0, 3, 25

-- File finding (fd/find with picker)
map("n", "<leader>ff", function()
  local cmd = vim.fn.executable("fd") == 1
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

-- Find by pattern (*.lua, *.py, etc)
map("n", "<leader>fp", function()
  local pattern = vim.fn.input("Pattern (*.lua, *.py, etc): ")
  if pattern == "" then return end

  local cmd = vim.fn.executable("fd") == 1
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

-- Search in files (grep/rg)
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

-- Search word under cursor
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

-- Buffer list
map("n", "<leader>fb", function()
  local buffers = vim.tbl_filter(function(buf)
    return vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buflisted
  end, vim.api.nvim_list_bufs())

  if #buffers == 0 then return print("No buffers") end

  local items = vim.tbl_map(function(buf)
    local name = vim.api.nvim_buf_get_name(buf)
    local display = name ~= "" and vim.fn.fnamemodify(name, ":~:.") or "[No Name]"
    local modified = vim.bo[buf].modified and " [+]" or ""
    local current = buf == vim.api.nvim_get_current_buf() and " %" or ""
    return { buf = buf, display = display .. modified .. current }
  end, buffers)

  vim.ui.select(items, {
    prompt = "Buffer:",
    format_item = function(item) return item.display end,
  }, function(choice)
    if choice then vim.api.nvim_set_current_buf(choice.buf) end
  end)
end, { desc = "List buffers" })

-- Recent files (filtered)
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

-- File explorer
map("n", "<leader>e", "<cmd>Lexplore<cr>", { desc = "Explorer sidebar" })

-- Browse directory in new tab (like original)
map("n", "-", function()
  local dir = vim.fn.expand("%:p:h")
  if dir == "" then dir = vim.fn.getcwd() end

  -- Open in new tab so bd works cleanly
  vim.cmd("tabnew")
  vim.cmd("Explore " .. vim.fn.fnameescape(dir))

  -- Set buffer-local close mappings (after netrw loads)
  vim.defer_fn(function()
    vim.keymap.set("n", "<Esc>", "<cmd>tabclose<cr>", { buffer = true, silent = true })
    vim.keymap.set("n", "q", "<cmd>tabclose<cr>", { buffer = true, silent = true })
  end, 50)
end, { desc = "Browse directory" })

-- Auto-setup Lexplore sidebar with close mappings
vim.api.nvim_create_autocmd("FileType", {
  pattern = "netrw",
  callback = function()
    -- For Lexplore sidebar, just toggle it
    vim.keymap.set("n", "<Esc>", "<cmd>Lexplore<cr>", { buffer = true, silent = true })
    vim.keymap.set("n", "q", "<cmd>Lexplore<cr>", { buffer = true, silent = true })
  end,
})

-- Alternate file (switch between two files)
map("n", "<leader><leader>", "<C-^>", { desc = "Alternate file" })

-- Marks navigator
map("n", "<leader>fm", function()
  local marks = vim.fn.getmarklist()
  local items = {}

  for _, mark in ipairs(marks) do
    if mark.mark:match("^'[a-zA-Z]$") then
      local buf = vim.api.nvim_buf_is_loaded(mark.pos[1]) and mark.pos[1] or nil
      if buf then
        local file = vim.api.nvim_buf_get_name(buf)
        local line = mark.pos[2]
        table.insert(items, {
          mark = mark.mark:sub(2),
          display = mark.mark:sub(2) .. " → " ..
                   (file ~= "" and vim.fn.fnamemodify(file, ":~:.") or "[No Name]") ..
                   ":" .. line
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
-- GIT (hunk-aware native implementation)
-- ============================================================================

if vim.fn.executable("git") == 1 then
  vim.fn.sign_define("GitAdd", { text = "+", texthl = "DiffAdd" })
  vim.fn.sign_define("GitChange", { text = "~", texthl = "DiffChange" })
  vim.fn.sign_define("GitDelete", { text = "_", texthl = "DiffDelete" })
  vim.fn.sign_define("GitTopDelete", { text = "‾", texthl = "DiffDelete" })

  -- Cache for git state per buffer
  local git_tracked = {}
  local git_hunks = {}  -- Store parsed hunks per buffer
  local update_timers = {}
  local inline_blame_enabled = {}
  local inline_blame_ns = vim.api.nvim_create_namespace("git_inline_blame")

  -- Parse git diff output into hunks and place signs
  local function parse_diff_and_place_signs(bufnr, diff_output)
    if not vim.api.nvim_buf_is_valid(bufnr) then return end

    vim.fn.sign_unplace("git_signs", { buffer = bufnr })
    git_hunks[bufnr] = {}

    local hunks = git_hunks[bufnr]
    local i = 1

    while i <= #diff_output do
      local line_text = diff_output[i]

      -- Match hunk header: @@ -old_start,old_count +new_start,new_count @@
      local old_start, old_count, new_start, new_count = line_text:match("^@@%s*%-(%d+),?(%d*)%s*%+(%d+),?(%d*)%s*@@")

      if old_start then
        old_start = tonumber(old_start)
        old_count = tonumber(old_count) or 1
        new_start = tonumber(new_start)
        new_count = tonumber(new_count) or 1

        -- Collect all diff lines for this hunk
        local diff_lines = { line_text }
        local hunk_start = new_start
        local hunk_end = new_start
        local current_line = new_start
        local has_add, has_del = false, false

        i = i + 1
        while i <= #diff_output and not diff_output[i]:match("^@@") do
          local d = diff_output[i]
          table.insert(diff_lines, d)

          if d:match("^%+") and not d:match("^%+%+%+") then
            has_add = true
            hunk_end = current_line
            current_line = current_line + 1
          elseif d:match("^%-") and not d:match("^%-%-%-") then
            has_del = true
          elseif d:match("^ ") then
            current_line = current_line + 1
          end
          i = i + 1
        end

        -- Determine hunk type
        local hunk_type
        if has_add and has_del then
          hunk_type = "change"
        elseif has_add then
          hunk_type = "add"
        else
          hunk_type = "delete"
        end

        -- For pure deletions, hunk_end should be same as start
        if not has_add then
          hunk_end = hunk_start
        end

        -- Store hunk
        table.insert(hunks, {
          start_line = hunk_start,
          end_line = hunk_end,
          type = hunk_type,
          diff_lines = diff_lines,
          old_start = old_start,
          old_count = old_count,
          new_start = new_start,
          new_count = new_count,
        })

        -- Place signs
        if hunk_type == "delete" then
          local sign_line = hunk_start > 0 and hunk_start or 1
          local sign_name = hunk_start == 0 and "GitTopDelete" or "GitDelete"
          vim.fn.sign_place(0, "git_signs", sign_name, bufnr, { lnum = sign_line, priority = 5 })
        else
          local sign_name = hunk_type == "change" and "GitChange" or "GitAdd"
          for lnum = hunk_start, hunk_end do
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

  local function update_git_signs()
    local bufnr = vim.api.nvim_get_current_buf()
    local file = vim.api.nvim_buf_get_name(bufnr)
    if file == "" or vim.bo.buftype ~= "" then return end

    -- Check if file is git-tracked (async, with cache)
    if git_tracked[bufnr] == nil then
      vim.system(
        { "git", "ls-files", "--error-unmatch", file },
        { text = true },
        vim.schedule_wrap(function(result)
          if not vim.api.nvim_buf_is_valid(bufnr) then return end
          git_tracked[bufnr] = result.code == 0

          -- Set signcolumn based on git tracking
          pcall(function()
            if git_tracked[bufnr] then
              vim.wo.signcolumn = "auto"
            else
              vim.wo.signcolumn = "no"
            end
          end)

          -- If tracked, start diff
          if git_tracked[bufnr] then
            update_git_signs()
          end
        end)
      )
      return
    end

    if not git_tracked[bufnr] then return end

    -- Run git diff async
    vim.system(
      { "git", "diff", "--no-color", "--no-ext-diff", "-U0", file },
      { text = true },
      vim.schedule_wrap(function(result)
        if not vim.api.nvim_buf_is_valid(bufnr) or result.code ~= 0 then return end
        local diff = vim.split(result.stdout, "\n", { trimempty = true })
        parse_diff_and_place_signs(bufnr, diff)
      end)
    )
  end

  -- Debounced update function
  local function schedule_update()
    local bufnr = vim.api.nvim_get_current_buf()
    if not git_tracked[bufnr] then return end

    -- Cancel pending timer
    if update_timers[bufnr] then
      update_timers[bufnr]:stop()
    end

    -- Schedule new update
    update_timers[bufnr] = vim.defer_fn(function()
      update_git_signs()
      update_timers[bufnr] = nil
    end, 500)
  end

  -- Update on file read and write
  vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
    callback = update_git_signs,
  })

  -- Update after typing stops (debounced)
  vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
    callback = schedule_update,
  })

  -- Clear cache and timers when buffer is deleted
  vim.api.nvim_create_autocmd("BufDelete", {
    callback = function(ev)
      if update_timers[ev.buf] then
        update_timers[ev.buf]:stop()
        update_timers[ev.buf] = nil
      end
      git_tracked[ev.buf] = nil
      git_hunks[ev.buf] = nil
      inline_blame_enabled[ev.buf] = nil
    end,
  })

  -- Find hunk at cursor line
  local function get_hunk_at_line(bufnr, line)
    local hunks = git_hunks[bufnr] or {}
    for _, hunk in ipairs(hunks) do
      if line >= hunk.start_line and line <= hunk.end_line then
        return hunk
      end
      if hunk.type == "delete" and line == hunk.start_line then
        return hunk
      end
    end
    return nil
  end

  -- Navigate to next/prev hunk
  local function goto_hunk(direction)
    local bufnr = vim.api.nvim_get_current_buf()
    local hunks = git_hunks[bufnr] or {}
    if #hunks == 0 then return print("No hunks") end

    local current_line = vim.fn.line(".")
    local target_hunk = nil

    if direction == "next" then
      for _, hunk in ipairs(hunks) do
        if hunk.start_line > current_line then
          target_hunk = hunk
          break
        end
      end
      if not target_hunk then target_hunk = hunks[1] end
    else
      for i = #hunks, 1, -1 do
        if hunks[i].start_line < current_line then
          target_hunk = hunks[i]
          break
        end
      end
      if not target_hunk then target_hunk = hunks[#hunks] end
    end

    if target_hunk then
      vim.api.nvim_win_set_cursor(0, { target_hunk.start_line, 0 })
    end
  end

  -- Generate patch for staging/resetting a hunk
  local function generate_hunk_patch(bufnr, hunk, reverse)
    local file = vim.api.nvim_buf_get_name(bufnr)
    local rel_path = vim.fn.systemlist("git ls-files --full-name " .. vim.fn.shellescape(file))[1]
    if not rel_path then return nil end

    local patch = {
      "--- a/" .. rel_path,
      "+++ b/" .. rel_path,
    }

    for _, line in ipairs(hunk.diff_lines) do
      if reverse then
        if line:match("^%+") and not line:match("^%+%+%+") then
          table.insert(patch, "-" .. line:sub(2))
        elseif line:match("^%-") and not line:match("^%-%-%-") then
          table.insert(patch, "+" .. line:sub(2))
        elseif line:match("^@@") then
          local old_s, old_c, new_s, new_c = line:match("^@@%s*%-(%d+),?(%d*)%s*%+(%d+),?(%d*)%s*@@")
          old_c = old_c ~= "" and old_c or "1"
          new_c = new_c ~= "" and new_c or "1"
          table.insert(patch, string.format("@@ -%s,%s +%s,%s @@", new_s, new_c, old_s, old_c))
        else
          table.insert(patch, line)
        end
      else
        table.insert(patch, line)
      end
    end

    return table.concat(patch, "\n") .. "\n"
  end

  -- Stage hunk at cursor
  local function stage_hunk()
    local bufnr = vim.api.nvim_get_current_buf()
    local line = vim.fn.line(".")
    local hunk = get_hunk_at_line(bufnr, line)

    if not hunk then return print("No hunk at cursor") end

    local patch = generate_hunk_patch(bufnr, hunk, false)
    if not patch then return print("Failed to generate patch") end

    local result = vim.fn.system("git apply --cached --unidiff-zero -", patch)
    if vim.v.shell_error == 0 then
      print("Staged hunk")
      update_git_signs()
    else
      print("Failed to stage hunk: " .. result)
    end
  end

  -- Stage visual selection (stages all hunks overlapping selection)
  local function stage_visual_selection()
    local bufnr = vim.api.nvim_get_current_buf()
    local start_line = vim.fn.line("'<")
    local end_line = vim.fn.line("'>")

    local hunks = git_hunks[bufnr] or {}
    local staged = 0

    for _, hunk in ipairs(hunks) do
      if hunk.start_line <= end_line and hunk.end_line >= start_line then
        local patch = generate_hunk_patch(bufnr, hunk, false)
        if patch then
          vim.fn.system("git apply --cached --unidiff-zero -", patch)
          if vim.v.shell_error == 0 then
            staged = staged + 1
          end
        end
      end
    end

    if staged > 0 then
      print("Staged " .. staged .. " hunk(s)")
      update_git_signs()
    else
      print("No hunks in selection")
    end
  end

  -- Reset hunk (discard changes)
  local function reset_hunk()
    local bufnr = vim.api.nvim_get_current_buf()
    local line = vim.fn.line(".")
    local hunk = get_hunk_at_line(bufnr, line)

    if not hunk then return print("No hunk at cursor") end

    local patch = generate_hunk_patch(bufnr, hunk, true)
    if not patch then return print("Failed to generate patch") end

    local result = vim.fn.system("git apply --unidiff-zero -", patch)
    if vim.v.shell_error == 0 then
      print("Reset hunk")
      vim.cmd("edit")
    else
      print("Failed to reset hunk: " .. result)
    end
  end

  -- Reset visual selection
  local function reset_visual_selection()
    local bufnr = vim.api.nvim_get_current_buf()
    local start_line = vim.fn.line("'<")
    local end_line = vim.fn.line("'>")

    local hunks = git_hunks[bufnr] or {}
    local reset_count = 0

    for _, hunk in ipairs(hunks) do
      if hunk.start_line <= end_line and hunk.end_line >= start_line then
        local patch = generate_hunk_patch(bufnr, hunk, true)
        if patch then
          vim.fn.system("git apply --unidiff-zero -", patch)
          if vim.v.shell_error == 0 then
            reset_count = reset_count + 1
          end
        end
      end
    end

    if reset_count > 0 then
      print("Reset " .. reset_count .. " hunk(s)")
      vim.cmd("edit")
    else
      print("No hunks in selection")
    end
  end

  -- Preview hunk in floating window
  local function preview_hunk()
    local bufnr = vim.api.nvim_get_current_buf()
    local line = vim.fn.line(".")
    local hunk = get_hunk_at_line(bufnr, line)

    if not hunk then return print("No hunk at cursor") end

    local preview_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(preview_buf, 0, -1, false, hunk.diff_lines)
    vim.bo[preview_buf].filetype = "diff"
    vim.bo[preview_buf].modifiable = false
    vim.bo[preview_buf].bufhidden = "wipe"

    local width = math.min(80, vim.o.columns - 4)
    local height = math.min(#hunk.diff_lines, math.floor(vim.o.lines * 0.4))

    local win = vim.api.nvim_open_win(preview_buf, true, {
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

    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = preview_buf, silent = true })
    vim.keymap.set("n", "<Esc>", "<cmd>close<cr>", { buffer = preview_buf, silent = true })

    vim.api.nvim_create_autocmd("WinLeave", {
      buffer = preview_buf,
      once = true,
      callback = function()
        if vim.api.nvim_win_is_valid(win) then
          vim.api.nvim_win_close(win, true)
        end
      end,
    })
  end

  -- Undo stage (unstage last staged hunk from this file)
  local function undo_stage_hunk()
    local file = vim.fn.expand("%:p")
    if file == "" then return print("No file") end

    local staged = vim.fn.systemlist("git diff --cached --no-color --no-ext-diff -U0 " .. vim.fn.shellescape(file))
    if #staged == 0 then return print("No staged changes for this file") end

    local rel_path = vim.fn.systemlist("git ls-files --full-name " .. vim.fn.shellescape(file))[1]
    if not rel_path then return print("File not tracked") end

    -- Find the last hunk
    local last_hunk_start = nil
    for i = #staged, 1, -1 do
      if staged[i]:match("^@@") then
        last_hunk_start = i
        break
      end
    end

    if not last_hunk_start then return print("No hunk found") end

    -- Build reversed patch
    local patch = {
      "--- a/" .. rel_path,
      "+++ b/" .. rel_path,
    }

    for i = last_hunk_start, #staged do
      local line = staged[i]
      if line:match("^%+") and not line:match("^%+%+%+") then
        table.insert(patch, "-" .. line:sub(2))
      elseif line:match("^%-") and not line:match("^%-%-%-") then
        table.insert(patch, "+" .. line:sub(2))
      elseif line:match("^@@") then
        local old_s, old_c, new_s, new_c = line:match("^@@%s*%-(%d+),?(%d*)%s*%+(%d+),?(%d*)%s*@@")
        old_c = old_c ~= "" and old_c or "1"
        new_c = new_c ~= "" and new_c or "1"
        table.insert(patch, string.format("@@ -%s,%s +%s,%s @@", new_s, new_c, old_s, old_c))
      else
        table.insert(patch, line)
      end
    end

    local patch_str = table.concat(patch, "\n") .. "\n"
    local result = vim.fn.system("git apply --cached --unidiff-zero -", patch_str)
    if vim.v.shell_error == 0 then
      print("Unstaged last hunk")
      update_git_signs()
    else
      print("Failed to unstage: " .. result)
    end
  end

  -- Inline blame toggle
  local function update_inline_blame(bufnr)
    if not inline_blame_enabled[bufnr] then
      vim.api.nvim_buf_clear_namespace(bufnr, inline_blame_ns, 0, -1)
      return
    end

    local file = vim.api.nvim_buf_get_name(bufnr)
    if file == "" then return end

    vim.system(
      { "git", "blame", "--line-porcelain", file },
      { text = true },
      vim.schedule_wrap(function(result)
        if not vim.api.nvim_buf_is_valid(bufnr) or result.code ~= 0 then return end
        if not inline_blame_enabled[bufnr] then return end

        vim.api.nvim_buf_clear_namespace(bufnr, inline_blame_ns, 0, -1)

        local lines = vim.split(result.stdout, "\n")
        local current_line = 0
        local author = ""
        local time = ""
        local commit = ""

        for _, line in ipairs(lines) do
          if line:match("^%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x") then
            commit = line:sub(1, 8)
            current_line = tonumber(line:match("%x+ %d+ (%d+)")) or 0
          elseif line:match("^author ") then
            author = line:sub(8)
          elseif line:match("^author%-time ") then
            local ts = tonumber(line:sub(13))
            if ts then
              time = os.date("%Y-%m-%d", ts)
            end
          elseif line:match("^\t") and current_line > 0 then
            local blame_text = string.format("  %s %s %s", commit, author, time)
            if commit:match("^0+$") then
              blame_text = "  Not committed yet"
            end
            pcall(vim.api.nvim_buf_set_extmark, bufnr, inline_blame_ns, current_line - 1, 0, {
              virt_text = { { blame_text, "Comment" } },
              virt_text_pos = "eol",
            })
          end
        end
      end)
    )
  end

  local function toggle_inline_blame()
    local bufnr = vim.api.nvim_get_current_buf()
    inline_blame_enabled[bufnr] = not inline_blame_enabled[bufnr]

    if inline_blame_enabled[bufnr] then
      print("Inline blame: ON")
      update_inline_blame(bufnr)
    else
      print("Inline blame: OFF")
      vim.api.nvim_buf_clear_namespace(bufnr, inline_blame_ns, 0, -1)
    end
  end

  -- Hunk navigation (respects diff mode)
  map("n", "]c", function()
    if vim.wo.diff then return "]c" end
    goto_hunk("next")
    return "<Ignore>"
  end, { expr = true, desc = "Next hunk" })

  map("n", "[c", function()
    if vim.wo.diff then return "[c" end
    goto_hunk("prev")
    return "<Ignore>"
  end, { expr = true, desc = "Prev hunk" })

  map("n", "<leader>gd", function()
    local file = vim.fn.expand("%")
    if file == "" then return print("No file") end

    local rel_path = vim.fn.systemlist("git ls-files --full-name " .. vim.fn.shellescape(vim.fn.expand("%:p")))[1]
    if vim.v.shell_error ~= 0 or not rel_path then return print("File not tracked") end

    local content = vim.fn.systemlist("git show HEAD:" .. rel_path)
    if vim.v.shell_error ~= 0 then return print("No HEAD version") end

    local ft = vim.bo.filetype
    local pos = vim.fn.getpos(".")

    vim.cmd("leftabove vnew")
    vim.bo.buftype = "nofile"
    vim.bo.bufhidden = "wipe"
    vim.bo.swapfile = false
    vim.api.nvim_buf_set_name(0, "HEAD:" .. vim.fn.fnamemodify(file, ":t"))
    vim.api.nvim_buf_set_lines(0, 0, -1, false, content)
    vim.bo.modifiable = false
    vim.bo.filetype = ft
    vim.cmd("diffthis")

    vim.cmd("wincmd p")
    vim.cmd("diffthis")
    vim.fn.setpos(".", pos)

    print("Diff mode: ]c/[c navigate, :diffoff to exit")
  end, { desc = "Diff file" })

  map("n", "<leader>gD", function()
    local diff = vim.fn.systemlist("git diff HEAD")
    if #diff == 0 then return print("No changes") end

    vim.cmd("tabnew")
    vim.bo.buftype = "nofile"
    vim.bo.bufhidden = "wipe"
    vim.api.nvim_buf_set_name(0, "git diff")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, diff)
    vim.bo.filetype = "diff"
    vim.bo.modifiable = false
    vim.keymap.set("n", "q", "<cmd>bd<cr>", { buffer = true })
  end, { desc = "Diff all" })

  map("n", "<leader>gb", function()
    local file = vim.fn.expand("%:p")
    if file == "" then return end

    local blame = vim.fn.systemlist("git blame --date=short " .. vim.fn.shellescape(file))
    if vim.v.shell_error ~= 0 then return print("Blame failed") end

    local line = vim.fn.line(".")

    vim.cmd("leftabove 40vnew")
    vim.bo.buftype = "nofile"
    vim.bo.bufhidden = "wipe"
    vim.api.nvim_buf_set_name(0, "blame")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, blame)
    vim.bo.modifiable = false
    vim.wo.wrap = false
    vim.wo.scrollbind = true
    vim.cmd("normal! " .. line .. "G")
    vim.keymap.set("n", "q", "<cmd>bd<cr>", { buffer = true })

    vim.cmd("wincmd p")
    vim.wo.scrollbind = true
    vim.cmd("normal! " .. line .. "G")
  end, { desc = "Blame" })

  map("n", "<leader>gl", function()
    local file = vim.fn.expand("%:p")
    local cmd = file ~= "" and ("git log --oneline -20 -- " .. vim.fn.shellescape(file)) or "git log --oneline -20"
    local log = vim.fn.systemlist(cmd)
    if #log == 0 then return print("No history") end

    vim.cmd("botright 10new")
    vim.bo.buftype = "nofile"
    vim.bo.bufhidden = "wipe"
    vim.api.nvim_buf_set_name(0, "git log")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, log)
    vim.bo.modifiable = false
    vim.keymap.set("n", "q", "<cmd>bd<cr>", { buffer = true })
  end, { desc = "Log" })

  -- Hunk actions
  map("n", "<leader>ga", stage_hunk, { desc = "Stage hunk" })
  map("v", "<leader>ga", function()
    vim.cmd("normal! ")
    stage_visual_selection()
  end, { desc = "Stage selection" })

  map("n", "<leader>gA", function()
    vim.fn.system("git add -A")
    if vim.v.shell_error == 0 then
      print("Staged all changes")
      update_git_signs()
    else
      print("Failed to stage changes")
    end
  end, { desc = "Stage all" })

  map("n", "<leader>gu", undo_stage_hunk, { desc = "Undo stage hunk" })

  map("n", "<leader>gU", function()
    local file = vim.fn.expand("%:p")
    if file == "" then return print("No file") end
    vim.fn.system("git reset HEAD " .. vim.fn.shellescape(file))
    if vim.v.shell_error == 0 then
      print("Unstaged buffer")
      update_git_signs()
    else
      print("Failed to unstage buffer")
    end
  end, { desc = "Unstage buffer" })

  map("n", "<leader>gr", reset_hunk, { desc = "Reset hunk" })
  map("v", "<leader>gr", function()
    vim.cmd("normal! ")
    reset_visual_selection()
  end, { desc = "Reset selection" })

  map("n", "<leader>gR", function()
    local file = vim.fn.expand("%:p")
    if file == "" then return print("No file") end
    vim.fn.system("git checkout -- " .. vim.fn.shellescape(file))
    if vim.v.shell_error == 0 then
      print("Reset buffer")
      vim.cmd("edit")
    else
      print("Failed to reset buffer")
    end
  end, { desc = "Reset buffer" })

  map("n", "<leader>gp", preview_hunk, { desc = "Preview hunk" })
  map("n", "<leader>gB", toggle_inline_blame, { desc = "Toggle inline blame" })

  map("n", "<leader>gs", "<cmd>!git status<cr>", { desc = "Status" })
  map("n", "<leader>gc", "<cmd>terminal git commit<cr>", { desc = "Commit" })
  map("n", "<leader>gP", "<cmd>!git push<cr>", { desc = "Push" })
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

map({"n", "v"}, "<leader>y", '"+y', { desc = "Yank to clipboard" })
map("n", "<leader>Y", '"+Y', { desc = "Yank line to clipboard" })
map({"n", "v"}, "<leader>p", '"+p', { desc = "Paste from clipboard" })

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
    "  <leader>li     LSP info & status",
    "",
    "DIAGNOSTICS",
    "  [d / ]d        Prev/Next diagnostic",
    "  <C-W>d         Show diagnostic float",
    "",
    "GIT               (prefix: <leader>g)",
    "  [c / ]c        Prev/Next hunk",
    "  <leader>ga     Stage hunk (visual: selection)",
    "  <leader>gA     Stage all",
    "  <leader>gu     Undo stage hunk",
    "  <leader>gr     Reset hunk (visual: selection)",
    "  <leader>gR     Reset buffer",
    "  <leader>gp     Preview hunk",
    "  <leader>gd     Diff file (side-by-side)",
    "  <leader>gD     Diff all (full diff)",
    "  <leader>gb     Blame (sidebar)",
    "  <leader>gB     Toggle inline blame",
    "  <leader>gl     Log (file or repo)",
    "  <leader>gs     Status",
    "  <leader>gc     Commit",
    "  <leader>gP     Push",
    "  Signs: + (add), ~ (change), _ (delete)",
    "",
    "NAVIGATION        (prefix: <leader>f)",
    "  <leader>ff     Find files (fuzzy)",
    "  <leader>fp     Find by pattern (*.lua, *.py)",
    "  <leader>fg     Search in files (grep)",
    "  <leader>fw     Search word under cursor",
    "  <leader>fb     Buffer list",
    "  <leader>fr     Recent files",
    "  <leader>fm     Marks list",
    "  <leader><leader> Alternate file (last 2)",
    "  <leader>e      Explorer sidebar",
    "  -              Browse current directory",
    "  gf             Go to file (default)",
    "",
    "WINDOWS",
    "  <C-h/j/k/l>    Navigate windows",
    "  <leader>-      Split horizontal",
    "  <leader>|      Split vertical",
    "",
    "BUFFERS",
    "  <Tab>/<S-Tab>  Next/Prev buffer",
    "  <leader>bd     Delete buffer",
    "  <leader>bl     List buffers",
    "  <leader>bo     Close hidden buffers",
    "",
    "EDITING",
    "  gcc / gc       Comment (native)",
    "  <leader>sw     Strip whitespace",
    "  <A-j/k>        Move line(s) down/up",
    "  < / >          Indent (visual, sticky)",
    "",
    "CLIPBOARD",
    "  <leader>y      Yank to clipboard",
    "  <leader>Y      Yank line to clipboard",
    "  <leader>p      Paste from clipboard",
    "",
    "QUICKFIX",
    "  [q / ]q        Prev/Next quickfix",
    "  <leader>qo     Open quickfix",
    "  <leader>qc     Close quickfix",
    "  [l / ]l        Prev/Next location",
    "  q (in qf)      Close quickfix window",
    "",
    "COMPLETION",
    "  <Tab>          Smart completion (LSP → keyword fallback)",
    "  <S-Tab>        Previous completion item",
    "  <Enter>        Accept completion",
    "  <C-n> / <C-p>  Keyword completion (built-in, always works)",
    "  <C-x><C-f>     File path completion (built-in)",
    "  <C-x><C-l>     Line completion (built-in)",
    "",
    "MISC",
    "  <leader>t      Terminal",
    "  <Esc><Esc>     Exit terminal mode",
    "  <leader>r      Run file",
    "  <leader>st     Set tab width",
    "  <F2>           Toggle auto-completion",
    "  <F3>           Cycle number modes",
    "",
    "COMMANDS",
    "  :StripWhitespace    Remove trailing whitespace",
    "  :SetTab [width]    Set tab/indent width (interactive if no arg)",
    "  :CloseHiddenBuffers Close all buffers not visible in windows",
    "  :ToggleNumber      Cycle number display modes",
    "",
    "═══════════════════════════════════════════════════════════",
    "  Press 'q' to close",
    "═══════════════════════════════════════════════════════════",
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

  vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, silent = true })
  vim.keymap.set("n", "<Esc>", "<cmd>close<cr>", { buffer = buf, silent = true })
end, { desc = "Show keymaps" })

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

local crg = vim.api.nvim_create_augroup("configReload", { clear = true })
vim.api.nvim_create_autocmd("BufWritePost", {
  group = crg,
  pattern = vim.env.MYVIMRC,
  callback = function()
    for k in pairs(package.loaded) do
      if k:match("^user") then package.loaded[k] = nil end
    end
    if pcall(vim.cmd, "source $MYVIMRC") then
      vim.notify("Config reloaded!", vim.log.levels.INFO)
    end
  end,
})

