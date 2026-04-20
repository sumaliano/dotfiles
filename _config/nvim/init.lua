-- ============================================================================
-- NEVIM MINIMAL CONFIGURATION (Plugin-Free)
-- ============================================================================

require('core')

-- LSP (Minimal Native Setup)
vim.lsp.enable({ "bashls", "pyright", "clangd", "rust_analyzer", "jdtls" })
vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(ev)
        vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"
        vim.keymap.set("n", "gry", vim.lsp.buf.type_definition, { buffer = ev.buf })
        vim.keymap.set("n", "grf", function() vim.lsp.buf.format({ async = true }) end, { buffer = ev.buf })
    end,
})

-- Diagnostics (Minimal Config)
vim.diagnostic.config { virtual_text = { prefix = ">" }, float = { border = "rounded", source = true } }
vim.keymap.set("n", "[e", function() vim.diagnostic.goto_prev { severity = vim.diagnostic.severity.ERROR } end)
vim.keymap.set("n", "]e", function() vim.diagnostic.goto_next { severity = vim.diagnostic.severity.ERROR } end)

-- Completion (Native logic)
local function smart_trigger()
    local line = vim.fn.getline('.')
    local col = vim.fn.col('.')
    local before = line:sub(1, col - 1)
    if before:match("[%./~]$") or before:match("/[%w%._%-]*$") then return "<C-x><C-f>"
    elseif vim.bo.omnifunc ~= "" then return "<C-x><C-o>"
    else return "<C-n>" end
end

vim.keymap.set("i", "<Tab>", function()
    if vim.fn.pumvisible() == 1 then return "<C-n>" end
    local col = vim.fn.col(".") - 1
    if col == 0 or vim.fn.getline("."):sub(col, col):match("%s") then return "<Tab>" end
    return smart_trigger()
end, { expr = true })
vim.keymap.set("i", "<S-Tab>", function() return vim.fn.pumvisible() == 1 and "<C-p>" or "<S-Tab>" end, { expr = true })
vim.keymap.set("i", "<cr>", function() return vim.fn.pumvisible() == 1 and "<c-y>" or "<cr>" end, { expr = true })

-- Auto-completion toggle
local auto_cmp = false
local auto_cmp_group = vim.api.nvim_create_augroup("AutoCmp", { clear = true })
local timer = vim.loop.new_timer()
vim.keymap.set("n", "<F2>", function()
    auto_cmp = not auto_cmp
    vim.api.nvim_clear_autocmds { group = auto_cmp_group }
    if auto_cmp then
        vim.api.nvim_create_autocmd("TextChangedI", {
            group = auto_cmp_group,
            callback = function()
                local char = vim.fn.getline("."):sub(vim.fn.col(".") - 1, vim.fn.col(".") - 1)
                if vim.fn.pumvisible() == 1 or vim.fn.col(".") < 3 or not char:match("[%w_%.%-%/~]") then return end
                timer:stop()
                timer:start(150, 0, vim.schedule_wrap(function()
                    if vim.api.nvim_get_mode().mode == 'i' then
                        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(smart_trigger(), true, false, true), "n", false)
                    end
                end))
            end
        })
    end
    print("Auto-completion: " .. (auto_cmp and "ON" or "OFF"))
end)

-- Smart close for special windows
local function smart_close()
    local buf = vim.api.nvim_get_current_buf()
    if not vim.api.nvim_buf_is_valid(buf) then return end
    local ft = vim.bo[buf].filetype
    local bt = vim.bo[buf].buftype

    if ft == "qf" then vim.cmd("cclose"); return true end
    if bt == "terminal" then
        if #vim.api.nvim_list_wins() > 1 then vim.cmd("close") else vim.cmd("stopinsert") end
        return true
    end
    if ft == "netrw" or ft == "diff" or bt == "help" or bt == "nofile" or ft == "lspinfo" or ft == "man" or vim.b[buf].is_git_diff then
        if #vim.api.nvim_list_wins() > 1 then
            vim.cmd("close")
        else
            local alt = vim.fn.bufnr("#")
            if alt ~= -1 and vim.fn.buflisted(alt) == 1 and alt ~= buf then
                vim.cmd("bdelete")
            else
                vim.cmd("enew")
                vim.api.nvim_buf_delete(buf, { force = true })
            end
        end
        return true
    end
    return false
end

local smart_logic = vim.api.nvim_create_augroup("SmartLogic", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
    group = smart_logic,
    pattern = { "qf", "netrw", "help", "man", "lspinfo", "checkhealth", "diff" },
    callback = function(ev) vim.keymap.set("n", "q", smart_close, { buffer = ev.buf, nowait = true, silent = true }) end,
})
vim.api.nvim_create_autocmd("TermOpen", {
    group = smart_logic,
    callback = function(ev) vim.keymap.set("n", "q", smart_close, { buffer = ev.buf, nowait = true, silent = true }) end,
})

-- Netrw navigation
vim.keymap.set("n", "-", function()
    if vim.bo.filetype == "netrw" then return vim.cmd("normal -") end
    pcall(vim.cmd, "Explore %:p:h")
end)

vim.keymap.set("n", "<leader>e", function()
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        local buf = vim.api.nvim_win_get_buf(win)
        if vim.bo[buf].filetype == "netrw" then
            vim.api.nvim_win_close(win, true)
            return
        end
    end
    vim.cmd("Lexplore %:p:h")
    vim.cmd("vertical resize 30")
end)

-- File finders (Native UI Select)
local function ui_sel(items, prompt, on_choice)
    if #items == 0 then return print("None found") end
    vim.ui.select(items, {prompt = prompt }, function(c) if c then on_choice(c) end end)
end

vim.keymap.set("n", "<leader>ff", function()
    local pattern = vim.fn.input("Find file: ")
    if pattern == "" then return end
    local cmd = vim.fn.executable("fd") == 1 and "fd -tf -H -E.git " .. vim.fn.shellescape(pattern)
                or "find . -type f ! -path '*/.git/*' -name " .. vim.fn.shellescape("*" .. pattern .. "*")
    local files = vim.fn.systemlist(cmd)
    if #files == 0 or (files[1] and files[1]:match("^error")) then return print("No files found") end
    local qf = {}
    for _, f in ipairs(files) do table.insert(qf, { filename = f, text = f }) end
    vim.fn.setqflist(qf, "r")
    if #files == 1 then vim.cmd("edit " .. vim.fn.fnameescape(files[1])) else vim.cmd("copen") end
end)

vim.keymap.set("n", "<leader>fr", function()
    ui_sel(vim.v.oldfiles, "Recent: ", function(f) vim.cmd("edit " .. vim.fn.fnameescape(f)) end)
end)

vim.keymap.set("n", "<leader>fb", function()
    local bufs = vim.api.nvim_list_bufs()
    local items = {}
    for _, b in ipairs(bufs) do
        if vim.api.nvim_buf_is_loaded(b) and vim.bo[b].buflisted then
            table.insert(items, vim.api.nvim_buf_get_name(b))
        end
    end
    ui_sel(items, "Buffers: ", function(f) vim.cmd("buffer " .. vim.fn.fnameescape(f)) end)
end)

vim.keymap.set("n", "<leader>fg", function()
    local pattern = vim.fn.input("Grep: ")
    if pattern == "" then return end
    vim.cmd("grep! " .. vim.fn.shellescape(pattern))
    vim.cmd("copen")
end)

-- ============================================================================
-- NATIVE GIT INTEGRATION
-- ============================================================================

local git_ns = vim.api.nvim_create_namespace("git_signs")
local cache, timers, diff_bufs = {}, {}, {}
local diff_mode = "unstaged"

local function git(cmd, stdin)
    local res = vim.fn.systemlist(cmd, stdin)
    return (vim.v.shell_error == 0) and res or nil
end

local function git_lines(cmd) return git(cmd) or {} end
local function get_rel_path(buf)
    local path = vim.api.nvim_buf_get_name(buf or 0)
    if path == "" then return nil end
    local root = git("git rev-parse --show-toplevel")
    return root and vim.fn.fnamemodify(path, ":p"):sub(#root[1] + 2) or nil
end

local function get_escaped_path() return vim.fn.shellescape(get_rel_path() or "") end

local function refresh_cache(buf)
    buf = buf or vim.api.nvim_get_current_buf()
    if not vim.api.nvim_buf_is_valid(buf) then return nil end
    local rel = get_rel_path(buf)
    if not rel then cache[buf] = nil; return nil end
    cache[buf] = {
        head = table.concat(git_lines("git show HEAD:" .. vim.fn.shellescape(rel)), "\n"),
        index = table.concat(git_lines("git show :0:" .. vim.fn.shellescape(rel)), "\n"),
    }
    return cache[buf]
end

local function get_sign_metadata(data)
    local res_type = data.u or data.s
    local suffix = (data.u and data.s) and "_b" or (data.s and "_s" or "")
    local config = {
        add = {   text = "│", hl = "GitSignAdd" },       change = {   text = "│", hl = "GitSignChange" },       del = {   text = "▁", hl = "GitSignDelete" },
        add_s = { text = "┃", hl = "GitSignAddStaged" }, change_s = { text = "┃", hl = "GitSignChangeStaged" }, del_s = { text = "▔", hl = "GitSignDeleteStaged" },
        add_b = { text = "║", hl = "GitSignAddBoth" },   change_b = { text = "║", hl = "GitSignChangeBoth" },   del_b = { text = "━", hl = "GitSignDeleteBoth" },
    }
    return config[res_type .. suffix] or config.change
end

local function update_signs(buf)
    buf = buf or vim.api.nvim_get_current_buf()
    local c = cache[buf]
    if not (c and c.index and c.head and vim.api.nvim_buf_is_valid(buf)) then return end

    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local buf_text = table.concat(lines, "\n")
    if vim.bo[buf].eol then buf_text = buf_text .. "\n" end

    local diff_opts = { result_type = "indices", algorithm = "histogram" }
    local staged_diffs = vim.diff(c.head, c.index, diff_opts) or {}
    local unstaged_diffs = vim.diff(c.index, buf_text, diff_opts) or {}
    local signs = {}

    for _, h in ipairs(unstaged_diffs) do
        local old_n, new_start, new_n = h[2], h[3], h[4]
        local t = old_n == 0 and "add" or new_n == 0 and "del" or "change"
        local start_l = (t == "del" and new_start == 0) and 1 or math.max(1, new_start)
        for l = start_l, start_l + math.max(new_n - 1, 0) do
            if l <= #lines then signs[l] = { u = t } end
        end
    end

    for _, s in ipairs(staged_diffs) do
        local s_old_n, s_new_start, s_new_n = s[2], s[3], s[4]
        local t = s_old_n == 0 and "add" or s_new_n == 0 and "del" or "change"
        local shifted_start = s_new_start
        for _, u in ipairs(unstaged_diffs) do
            if u[1] < s_new_start then shifted_start = shifted_start + (u[4] - u[2]) end
        end
        for l = math.max(1, shifted_start), math.max(1, shifted_start) + math.max(s_new_n - 1, 0) do
            if l <= #lines then
                signs[l] = signs[l] or {}
                signs[l].s = t
            end
        end
    end

    vim.api.nvim_buf_clear_namespace(buf, git_ns, 0, -1)
    for l, data in pairs(signs) do
        local meta = get_sign_metadata(data)
        vim.api.nvim_buf_set_extmark(buf, git_ns, l - 1, 0, { sign_text = meta.text, sign_hl_group = meta.hl, priority = 100 })
    end
end

-- Sign Highlights
local function setup_git_highlights()
    local function hl(name, opts) vim.api.nvim_set_hl(0, name, opts) end
    hl("GitSignAdd",          { fg = "#3fb950" })
    hl("GitSignChange",       { fg = "#d29922" })
    hl("GitSignDelete",       { fg = "#f85149" })
    hl("GitSignAddStaged",    { fg = "#2d5a3d" })
    hl("GitSignChangeStaged", { fg = "#6b5416" })
    hl("GitSignDeleteStaged", { fg = "#6b2020" })
    hl("GitSignAddBoth",      { fg = "#3fb950", bg = "#1a4d2e" })
    hl("GitSignChangeBoth",   { fg = "#d29922", bg = "#6b5416" })
    hl("GitSignDeleteBoth",   { fg = "#f85149", bg = "#6b2020" })
end
setup_git_highlights()
vim.api.nvim_create_autocmd("ColorScheme", { callback = setup_git_highlights })

-- Refresh logic
local function refresh(buf, reload)
    buf = buf or vim.api.nvim_get_current_buf()
    if reload then vim.cmd("e!") end
    refresh_cache(buf)
    update_signs(buf)
end

vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "FocusGained" }, { callback = function(ev) refresh(ev.buf) end })
vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, { callback = function(ev) update_signs(ev.buf) end })

-- Git Keymaps
vim.keymap.set("n", "<leader>gd", function() vim.cmd("DiffviewOpen") end) -- Fallback if diffview exists
vim.keymap.set("n", "<leader>gs", function()
    local status = git_lines("git status --porcelain")
    if #status == 0 then return print("Clean") end
    local qf = {}
    for _, line in ipairs(status) do table.insert(qf, { filename = line:sub(4), text = line:sub(1, 2) }) end
    vim.fn.setqflist(qf, "r")
    vim.fn.setqflist({}, "a", { title = "Git Status" })
    vim.cmd("copen")
end)

-- Help menu (Minimal)
vim.keymap.set("n", "<leader>?", function()
    print([[
    GENERAL:  w/q/Q save/quit/toggle-qf | ff/fr/fb/fg find | e/- explore | y/p clip | bd buf | Tab nav | M-hjkl win
    r replace | R run | cc/cr config/reload | F2 auto-cmp | F3 numbers | sw strip | st tab | cd root
    GIT:      gs status | gd diff | ]c/[c hunk | gs status | ga add | gu restore --staged | gr restore
    LSP/DIAG: gry type | grf format | [e/]e error | K hover
    GUTTER:   green=add orange=change red=delete | bright=unstaged dim=staged bg=both]])
end)
