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
opt.cursorline, opt.signcolumn = true, "yes"
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
-- LSP & DIAGNOSTICS
-- ============================================================================
-- Install LSP servers:
--   Python:  pip install pyright
--   Bash:    npm install -g bash-language-server
--   Rust:    rustup component add rust-analyzer
--   Java:    https://github.com/eclipse-jdtls/eclipse.jdt.ls
--   C/C++:   Install clangd from package manager
--
-- Check status: <leader>li

local lsp_servers = {
  { name = "bashls", cmd = { "bash-language-server", "start" }, ft = { "sh", "bash", "zsh" }, root = { ".git" } },
  { name = "pyright", cmd = { "pyright-langserver", "--stdio" }, ft = { "python" }, root = { "pyproject.toml", "setup.py", "requirements.txt", ".git" } },
  { name = "jdtls", cmd = { "jdtls" }, ft = { "java" }, root = { "pom.xml", "build.gradle", ".git" } },
  { name = "rust_analyzer", cmd = { "rust-analyzer" }, ft = { "rust" }, root = { "Cargo.toml", ".git" } },
  { name = "clangd", cmd = { "clangd" }, ft = { "c", "cpp" }, root = { "compile_commands.json", ".git" } },
}

local available_servers = {}
for _, server in ipairs(lsp_servers) do
  if vim.fn.executable(server.cmd[1]) == 1 then
    table.insert(available_servers, server)
  end
end

for _, server in ipairs(available_servers) do
  vim.api.nvim_create_autocmd("FileType", {
    pattern = server.ft,
    callback = function(args)
      local clients = vim.lsp.get_clients({ bufnr = args.buf, name = server.name })
      if #clients > 0 then return end

      local root = vim.fs.dirname(vim.fs.find(server.root, { upward = true })[1])
      if not root then root = vim.fn.getcwd() end

      local ok = pcall(vim.lsp.start, {
        name = server.name,
        cmd = server.cmd,
        root_dir = root,
      })

      if not ok then
        vim.notify("Failed to start " .. server.name, vim.log.levels.WARN)
      end
    end,
  })
end

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    -- Set omnifunc
    vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"

    local function m(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = ev.buf, silent = true, desc = desc })
    end

    m("n", "gd", vim.lsp.buf.definition, "Definition")
    m("n", "gD", vim.lsp.buf.declaration, "Declaration")
    m("n", "gr", vim.lsp.buf.references, "References")
    m("n", "gi", vim.lsp.buf.implementation, "Implementation")
    m("n", "gy", vim.lsp.buf.type_definition, "Type definition")
    m("n", "K", vim.lsp.buf.hover, "Hover")
    m("n", "<C-s>", vim.lsp.buf.signature_help, "Signature help")
    m("i", "<C-s>", vim.lsp.buf.signature_help, "Signature help")
    m("n", "<leader>rn", vim.lsp.buf.rename, "Rename")
    m("n", "<leader>ca", vim.lsp.buf.code_action, "Code action")
    m("n", "<leader>f", function() vim.lsp.buf.format({ async = true }) end, "Format")
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

map("n", "<leader>d", vim.diagnostic.open_float, { desc = "Show diagnostic" })
map("n", "[d", vim.diagnostic.goto_prev, { desc = "Prev diagnostic" })
map("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
map("n", "[e", function() vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.ERROR }) end, { desc = "Prev error" })
map("n", "]e", function() vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.ERROR }) end, { desc = "Next error" })

-- ============================================================================
-- COMPLETION
-- ============================================================================

map("i", "<Tab>", function()
  if vim.fn.pumvisible() == 1 then return "<C-n>" end
  local col = vim.fn.col('.') - 1
  if col == 0 or vim.fn.getline('.'):sub(col, col):match('%s') then return "<Tab>" end
  local line = vim.fn.getline('.')
  local before = line:sub(1, col)
  if before:match('[~/.]?/?[%w._/-]*$') and (before:match('/') or before:match('^%.') or before:match('^~')) then
    return "<C-x><C-f>"
  end
  return "<C-x><C-o>"
end, { expr = true })

map("i", "<S-Tab>", function()
  return vim.fn.pumvisible() == 1 and "<C-p>" or "<S-Tab>"
end, { expr = true })

map("i", "<CR>", function()
  return vim.fn.pumvisible() == 1 and "<C-y>" or "<CR>"
end, { expr = true })

map("i", "<C-Space>", "<C-x><C-o>")
map("i", "<C-f>", "<C-x><C-f>")
map("i", "<C-e>", function()
  return vim.fn.pumvisible() == 1 and "<C-e>" or "<End>"
end, { expr = true })

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
            if before:match('[%w_][%w_]+$') or before:match('%.$') or before:match('->$') or before:match('::$') then
              vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-x><C-o>', true, false, true), 'n', false)
            end
          end
        end, 100)
      end,
    })
    print("Auto-completion: ON")
  else
    vim.api.nvim_clear_autocmds({ group = auto_complete_group })
    print("Auto-completion: OFF")
  end
end, { desc = "Toggle auto-completion" })

-- ============================================================================
-- EDITING
-- ============================================================================

local function toggle_comment()
  local cs = vim.bo.commentstring
  if not cs or cs == "" then return end
  local comment = cs:gsub("%%s", "")
  local line1, line2 = vim.fn.line("."), vim.fn.line("v")
  if line2 < line1 then line1, line2 = line2, line1 end

  for lnum = line1, line2 do
    local line = vim.fn.getline(lnum)
    if line:match("^%s*" .. vim.pesc(comment)) then
      line = line:gsub("^(%s*)" .. vim.pesc(comment) .. "%s?", "%1")
    else
      line = line:gsub("^(%s*)", "%1" .. comment .. " ")
    end
    vim.fn.setline(lnum, line)
  end
end

map("n", "gcc", toggle_comment, { desc = "Comment line" })
map("v", "gc", function() toggle_comment(); vim.cmd("normal! gv") end, { desc = "Comment" })
map("n", "<C-_>", toggle_comment, { desc = "Comment line" })
map("v", "<C-_>", function() toggle_comment(); vim.cmd("normal! gv") end, { desc = "Comment" })

-- ============================================================================
-- UTILITY FUNCTIONS
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
map("n", "<leader>bh", close_hidden_buffers, { desc = "Close hidden buffers" })

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

map("n", "<leader>ff", function()
  vim.cmd("edit " .. vim.fn.fnameescape(vim.fn.input("Find: ", "", "file")))
end, { desc = "Find files" })

map("n", "<leader>fd", function()
  local pattern = vim.fn.input("Pattern: ", "*.yml")
  local files = vim.fn.systemlist("find . -type f -name '" .. pattern .. "' 2>/dev/null")
  if #files == 0 then print("No files found") return end
  vim.ui.select(files, { prompt = "Select:" }, function(choice)
    if choice then vim.cmd("edit " .. vim.fn.fnameescape(choice)) end
  end)
end, { desc = "Find by pattern" })

map("n", "<leader>fg", function()
  local search = vim.fn.input("Grep: ")
  if search == "" then return end
  if vim.fn.executable("rg") == 1 then
    vim.cmd("grep! " .. vim.fn.shellescape(search))
    vim.cmd("copen")
  elseif vim.fn.executable("grep") == 1 then
    vim.cmd("grep! -r " .. vim.fn.shellescape(search) .. " .")
    vim.cmd("copen")
  else
    print("No grep tool found")
  end
end, { desc = "Grep" })

map("n", "<leader>fr", function()
  vim.ui.select(vim.v.oldfiles, { prompt = "Recent:" }, function(choice)
    if choice then vim.cmd("edit " .. vim.fn.fnameescape(choice)) end
  end)
end, { desc = "Recent" })

map("n", "<leader>e", "<cmd>Lexplore<cr>", { desc = "Explorer" })
map("n", "-", function()
  vim.cmd("tabe | Explore")
  vim.cmd("nnoremap <buffer> <Esc> :bd!<CR>")
  vim.cmd("nnoremap <buffer> q :bd!<CR>")
end, { desc = "Explorer" })

-- ============================================================================
-- GIT
-- ============================================================================

if vim.fn.executable("git") == 1 then
  vim.fn.sign_define("GitAdd", { text = "+", texthl = "DiffAdd" })
  vim.fn.sign_define("GitChange", { text = "~", texthl = "DiffChange" })
  vim.fn.sign_define("GitDelete", { text = "_", texthl = "DiffDelete" })

  local function update_git_signs()
    local bufnr = vim.api.nvim_get_current_buf()
    local file = vim.api.nvim_buf_get_name(bufnr)
    if file == "" or vim.bo.buftype ~= "" then return end

    local tracked = vim.fn.system("git ls-files --error-unmatch " .. vim.fn.shellescape(file) .. " 2>/dev/null")
    if vim.v.shell_error ~= 0 then return end

    local diff = vim.fn.systemlist("git diff --no-color --no-ext-diff -U0 " .. vim.fn.shellescape(file) .. " 2>/dev/null")
    if vim.v.shell_error ~= 0 then return end

    vim.fn.sign_unplace("git_signs", { buffer = bufnr })

    local line = 0
    local i = 1
    while i <= #diff do
      local d = diff[i]
      if d:match("^@@") then
        local old_start, old_count, new_start, new_count = d:match("@@%s*%-(%d+),?(%d*)%s*%+(%d+),?(%d*)%s*@@")
        new_start = tonumber(new_start)
        line = new_start

        local has_del, has_add = false, false
        for j = i + 1, math.min(i + 30, #diff) do
          if diff[j]:match("^@@") then break end
          if diff[j]:match("^%-") and not diff[j]:match("^%-%-%-") then has_del = true end
          if diff[j]:match("^%+") and not diff[j]:match("^%+%+%+") then has_add = true end
        end
        local is_change = has_del and has_add

        i = i + 1
        while i <= #diff and not diff[i]:match("^@@") do
          d = diff[i]
          if d:match("^%+") and not d:match("^%+%+%+") then
            local sign = is_change and "GitChange" or "GitAdd"
            vim.fn.sign_place(0, "git_signs", sign, bufnr, { lnum = line, priority = 5 })
            line = line + 1
          elseif d:match("^%-") and not d:match("^%-%-%-") then
            local del_line = line > 1 and line or 1
            vim.fn.sign_place(0, "git_signs", "GitDelete", bufnr, { lnum = del_line, priority = 5 })
          elseif d:match("^ ") then
            line = line + 1
          end
          i = i + 1
        end
      else
        i = i + 1
      end
    end
  end

  vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
    callback = function() vim.defer_fn(update_git_signs, 100) end,
  })

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

  map("n", "<leader>ga", function()
    local file = vim.fn.expand("%:p")
    if file == "" then return print("No file") end
    vim.fn.system("git add " .. vim.fn.shellescape(file))
    if vim.v.shell_error == 0 then
      print("Staged: " .. vim.fn.expand("%"))
    else
      print("Failed to stage file")
    end
  end, { desc = "Stage file" })

  map("n", "<leader>gA", function()
    vim.fn.system("git add -A")
    if vim.v.shell_error == 0 then
      print("Staged all changes")
    else
      print("Failed to stage changes")
    end
  end, { desc = "Stage all" })

  map("n", "<leader>gu", function()
    local file = vim.fn.expand("%:p")
    if file == "" then return print("No file") end
    vim.fn.system("git reset HEAD " .. vim.fn.shellescape(file))
    if vim.v.shell_error == 0 then
      print("Unstaged: " .. vim.fn.expand("%"))
    else
      print("Failed to unstage file")
    end
  end, { desc = "Unstage file" })

  map("n", "<leader>gs", "<cmd>!git status<cr>", { desc = "Status" })
  map("n", "<leader>gc", "<cmd>terminal git commit<cr>", { desc = "Commit" })
  map("n", "<leader>gp", "<cmd>!git push<cr>", { desc = "Push" })
end

-- ============================================================================
-- KEYMAPS
-- ============================================================================

map("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear highlight" })
map("n", "<leader>w", "<cmd>w<cr>", { desc = "Save" })
map("n", "<leader>q", "<cmd>q<cr>", { desc = "Quit" })
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
  table.insert(info, "Available servers: " .. (#available_servers > 0 and table.concat(vim.tbl_map(function(s) return s.name end, available_servers), ", ") or "none"))
  table.insert(info, "Log: " .. vim.lsp.get_log_path())

  vim.notify(table.concat(info, "\n"), vim.log.levels.INFO)
end, { desc = "LSP info" })

map("n", "<leader>ec", function()
  vim.cmd.edit(vim.fn.stdpath("config") .. "/init.lua")
end, { desc = "Edit config" })

map("n", "<leader>?", function()
  local lsp_status = #available_servers > 0 and
    string.format("(%d/%d available)", #available_servers, #lsp_servers) or "(none installed)"

  local help = {
    "═══════════════════════════════════════════════════════════",
    "                    CUSTOM KEYMAPS",
    "═══════════════════════════════════════════════════════════",
    "",
    "GENERAL",
    "  <leader>w      Save",
    "  <leader>q      Quit",
    "  <leader>Q      Quit all",
    "  <Esc>          Clear search highlight",
    "  <leader>ec     Edit config",
    "  <leader>?      Show this help",
    "",
    "LSP NAVIGATION    " .. lsp_status,
    "  gd             Go to definition",
    "  gD             Go to declaration",
    "  gr             Go to references",
    "  gi             Go to implementation",
    "  gy             Go to type definition",
    "  K              Hover documentation",
    "  <C-s>          Signature help",
    "",
    "LSP ACTIONS",
    "  <leader>rn     Rename symbol",
    "  <leader>ca     Code action",
    "  <leader>f      Format buffer",
    "  <leader>li     LSP info & status",
    "",
    "DIAGNOSTICS",
    "  <leader>d      Show diagnostic float",
    "  [d / ]d        Prev/Next diagnostic",
    "  [e / ]e        Prev/Next error",
    "",
    "GIT               (prefix: <leader>g)",
    "  <leader>gd     Diff file (side-by-side)",
    "  <leader>gD     Diff all (full diff)",
    "  <leader>gb     Blame (scroll-synced)",
    "  <leader>gl     Log (file or repo)",
    "  <leader>ga     Stage file",
    "  <leader>gA     Stage all",
    "  <leader>gu     Unstage file",
    "  <leader>gs     Status",
    "  <leader>gc     Commit",
    "  <leader>gp     Push",
    "  Signs: + (add), ~ (change), _ (delete)",
    "",
    "FILES             (prefix: <leader>f)",
    "  <leader>ff     Find file",
    "  <leader>fd     Find by pattern",
    "  <leader>fg     Grep",
    "  <leader>fr     Recent files",
    "  <leader>e      Explorer (sidebar)",
    "  -              Explorer (fullscreen)",
    "",
    "WINDOWS",
    "  <C-h/j/k/l>    Navigate windows",
    "  <leader>-      Split horizontal",
    "  <leader>|      Split vertical",
    "",
    "BUFFERS",
    "  <Tab>          Next buffer",
    "  <S-Tab>        Prev buffer",
    "  <leader>bd     Delete buffer",
    "  <leader>bh     Close hidden buffers",
    "",
    "EDITING",
    "  gcc / <C-/>    Toggle comment (line)",
    "  gc             Toggle comment (visual)",
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

