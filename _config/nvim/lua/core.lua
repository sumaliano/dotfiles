-- ============================================================================
-- SHARED CORE CONFIGURATION (The Brain)
-- ============================================================================

local o, g, map = vim.opt, vim.g, vim.keymap.set
g.mapleader, g.maplocalleader = " ", " "

-- Settings
for k, v in pairs({
    number = true, relativenumber = true, cursorline = true, signcolumn = "auto",
    expandtab = true, shiftwidth = 4, tabstop = 4, smartindent = true,
    ignorecase = true, smartcase = true, hlsearch = true, incsearch = true,
    splitright = true, splitbelow = true, wrap = false, scrolloff = 8, sidescrolloff = 8,
    swapfile = false, backup = false, writebackup = false, undofile = true, updatetime = 300, 
    timeoutlen = 500, ttimeoutlen = 50,
    completeopt = "menu,menuone,noselect,noinsert", pumheight = 10,
    list = true, mouse = "", showmode = false, laststatus = 3, termguicolors = true,
    hidden = true, autoread = true, showcmd = true
}) do o[k] = v end

o.listchars = { tab = "| ", trail = ".", nbsp = "+" }
o.diffopt:append({ "vertical", "linematch:60", "algorithm:histogram", "indent-heuristic", "internal" })
o.shortmess:append("c")

-- Colorscheme with fallback
local colors = { "retrobox", "badwolf", "gruvbox", "desert" }
for _, c in ipairs(colors) do
    if pcall(vim.cmd.colorscheme, c) then break end
end

-- ============================================================================
-- STATUSLINE (Native & Fast)
-- ============================================================================

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

vim.api.nvim_create_autocmd({ "BufEnter", "DirChanged" }, { callback = update_branch })
_G.statusline_fn = statusline
vim.o.statusline = "%!v:lua.statusline_fn()"

-- ============================================================================
-- SHARED KEYMAPS
-- ============================================================================

-- General
map("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear highlight" })
map("i", "jk", "<Esc>", { desc = "Exit insert mode with jk" })
map("n", "<leader>w", "<cmd>w<cr>", { desc = "Save" })
map("n", "<leader>q", "<cmd>q<cr>", { desc = "Quit" })
map("n", "<leader>Q", "<cmd>qa<cr>", { desc = "Quit all" })

-- Toggle quickfix
map("n", "Q", function()
    for _, win in ipairs(vim.fn.getwininfo()) do
        if win.quickfix == 1 then vim.cmd("cclose"); return end
    end
    if vim.fn.empty(vim.fn.getqflist()) == 1 then print("Quickfix empty") else vim.cmd("copen") end
end, { desc = "Toggle quickfix" })

-- Windows (with tmux integration)
local function nvim_tmux_nav(direction)
    local win = vim.api.nvim_get_current_win()
    vim.cmd('wincmd ' .. direction)
    if win == vim.api.nvim_get_current_win() then
        local tmux_dir = {h = 'L', j = 'D', k = 'U', l = 'R'}
        vim.fn.system('tmux select-pane -' .. tmux_dir[direction])
    end
end

map('n', '<M-h>', function() nvim_tmux_nav('h') end, { desc = "Left" })
map('n', '<M-j>', function() nvim_tmux_nav('j') end, { desc = "Down" })
map('n', '<M-k>', function() nvim_tmux_nav('k') end, { desc = "Up" })
map('n', '<M-l>', function() nvim_tmux_nav('l') end, { desc = "Right" })

map("n", "<leader>-", "<cmd>split<cr>", { desc = "Split horizontal" })
map("n", "<leader>|", "<cmd>vsplit<cr>", { desc = "Split vertical" })

-- Buffers
map("n", "<Tab>", "<cmd>bnext<cr>", { desc = "Next buffer" })
map("n", "<S-Tab>", "<cmd>bprevious<cr>", { desc = "Prev buffer" })
map("n", "<leader>bd", "<cmd>bdelete<cr>", { desc = "Delete buffer" })

-- Terminal
map("n", "<leader>t", "<cmd>terminal<cr>", { desc = "Terminal" })
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal" })

-- Clipboard
map({ "n", "v" }, "<leader>y", '"+y', { desc = "Yank to clipboard" })
map({ "n", "v" }, "<leader>p", '"+p', { desc = "Paste from clipboard" })

-- Indent
map("v", "<", "<gv")
map("v", ">", ">gv")

-- Move lines
map("v", "<A-j>", ":m '>+1<cr>gv=gv", { desc = "Move down" })
map("v", "<A-k>", ":m '<-2<cr>gv=gv", { desc = "Move up" })

-- Lightweight Auto-Pairs (Parentheses, Brackets, Quotes)
map("i", "(", "()<left>", { desc = "Auto-pair (" })
map("i", "[", "[]<left>", { desc = "Auto-pair [" })
map("i", "{", "{}<left>", { desc = "Auto-pair {" })
map("i", "\"", "\"\"<left>", { desc = "Auto-pair \"" })
map("i", "'", "''<left>", { desc = "Auto-pair '" })
map("i", "`", "``<left>", { desc = "Auto-pair `" })

-- Quick-close brackets with <C-j>
map("i", "<C-j>", "<esc>A;<esc>", { desc = "Close line with semicolon" })
map("i", "<C-k>", "<esc>A<cr>", { desc = "Break line at end" })

-- Quickfix navigation
map("n", "[q", "<cmd>cprev<cr>", { desc = "Prev quickfix" })
map("n", "]q", "<cmd>cnext<cr>", { desc = "Next quickfix" })

-- Toggle numbers
map("n", "<F3>", function()
    o.number, o.relativenumber = not o.number:get(), not o.relativenumber:get()
    print("Line numbers: " .. (o.number:get() and "ON" or "OFF"))
end, { desc = "Cycle number modes" })

-- Config management
map("n", "<leader>cc", function() 
    local entry = vim.fn.expand("$MYVIMRC")
    if entry == "" or entry:match("core.lua") then entry = vim.fn.stdpath("config") .. "/init.lua" end
    vim.cmd("e " .. entry) 
end, { desc = "Edit config" })

map("n", "<leader>cr", function()
    for _, group in ipairs(vim.api.nvim_get_autocmds({})) do
        if group.group_name and not group.group_name:match("^nvim") then
            pcall(vim.api.nvim_del_augroup_by_name, group.group_name)
        end
    end
    local entry = vim.fn.expand("$MYVIMRC")
    if entry == "" or entry:match("core.lua") then entry = vim.fn.stdpath("config") .. "/init.lua" end
    dofile(entry)
    print("Config reloaded: " .. entry)
end, { desc = "Reload config" })

-- Alternate file
map("n", "<leader><leader>", "<C-^>", { desc = "Alternate file" })

-- Change directory
map("n", "<leader>cd", function()
    local git_root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
    if vim.v.shell_error == 0 and git_root then
        vim.cmd("cd " .. vim.fn.fnameescape(git_root))
    else
        vim.cmd("cd %:p:h")
    end
    print("CWD: " .. vim.fn.getcwd())
end, { desc = "cd to project root" })

-- Replace
map("n", "<leader>r", function()
    local word = vim.fn.expand("<cword>")
    vim.fn.feedkeys(":%s/\\<" .. word .. "\\>/" .. word .. "/gc", "n")
    vim.fn.feedkeys(string.rep("\b", #word + 3), "n")
end, { desc = "Replace word" })

map("v", "<leader>r", function()
    vim.cmd('normal! "zy')
    local selection = vim.fn.getreg("z")
    local escaped = vim.fn.escape(selection, "\\/")
    vim.fn.feedkeys(":%s/\\V" .. escaped .. "/" .. selection .. "/gc", "n")
    vim.fn.feedkeys(string.rep("\b", #selection + 3), "n")
end, { desc = "Replace selection" })

-- Run
map("n", "<leader>R", function()
    local file = vim.fn.shellescape(vim.fn.expand("%:p"))
    local cmds = { python = "python3 " .. file, sh = "bash " .. file, bash = "bash " .. file, lua = "lua " .. file, c = "gcc " .. file .. " -o /tmp/a.out && /tmp/a.out", rust = "cargo run" }
    local cmd = cmds[vim.bo.filetype]
    if cmd then vim.cmd("terminal " .. cmd) else print("No run command for: " .. vim.bo.filetype) end
end, { desc = "Run file" })

-- ============================================================================
-- SHARED UTILITIES
-- ============================================================================

_G.strip_whitespace = function()
    local v = vim.fn.winsaveview(); vim.cmd([[%s/\s\+$//e]]); vim.fn.winrestview(v); print("Stripped whitespace")
end
map("n", "<leader>sw", _G.strip_whitespace, { desc = "Strip whitespace" })

_G.set_tab = function()
    local n = tonumber(vim.fn.input("Tab width: ")); if n then vim.bo.tabstop, vim.bo.shiftwidth = n, n end
end
map("n", "<leader>st", _G.set_tab, { desc = "Set tab width" })

_G.close_hidden_buffers = function()
    local visible, closed = {}, 0
    for _, w in ipairs(vim.api.nvim_list_wins()) do visible[vim.api.nvim_win_get_buf(w)] = true end
    for _, b in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(b) and not visible[b] and vim.bo[b].buftype == "" then
            pcall(vim.api.nvim_buf_delete, b, {})
            closed = closed + 1
        end
    end
    print("Closed " .. closed .. " hidden buffers")
end
map("n", "<leader>bo", _G.close_hidden_buffers, { desc = "Close hidden buffers" })

-- ============================================================================
-- SHARED AUTOCOMMANDS
-- ============================================================================

local autocmd = vim.api.nvim_create_autocmd
autocmd("TextYankPost", { callback = function() vim.highlight.on_yank() end })
autocmd("BufReadPost", { callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(0) then pcall(vim.api.nvim_win_set_cursor, 0, mark) end
end })

-- YAML/Markdown fixes
autocmd("FileType", { pattern = { "yaml", "yml" }, callback = function() vim.bo.commentstring = "# %s" end })
autocmd("FileType", { pattern = { "gitcommit", "markdown" }, callback = function()
    vim.opt_local.wrap, vim.opt_local.spell = true, true
end })

-- Auto-close terminal buffers (with Gitsigns refresh if available)
autocmd("TermClose", { 
    callback = function(ev) 
        if vim.b[ev.buf].is_git_terminal then
            vim.schedule(function()
                local ok, gs = pcall(require, "gitsigns")
                if ok then gs.refresh() end
                vim.cmd("bd!")
            end)
        else
            vim.cmd("bd!") 
        end
    end, 
})
