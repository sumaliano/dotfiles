-- Shortcuts
local o, g, map = vim.opt, vim.g, vim.keymap.set
g.mapleader, g.maplocalleader = " ", " "

-- Settings
for k, v in pairs {
    number = true, relativenumber = true, cursorline = true, signcolumn = "auto",
    expandtab = true, shiftwidth = 4, tabstop = 4, smartindent = true,
    ignorecase = true, smartcase = true, hlsearch = true,
    splitright = true, splitbelow = true, wrap = false, scrolloff = 8,
    swapfile = false, backup = false, updatetime = 300, timeoutlen = 500, ttimeoutlen = 50,
    completeopt = "menu,menuone,noselect,noinsert", pumheight = 10,
    list = true, mouse = "", showmode = false, laststatus = 2, termguicolors = true
} do o[k] = v end
o.listchars = { tab = "| ", trail = ".", nbsp = "+" }
o.diffopt:append { "vertical", "linematch:60", "algorithm:histogram", "indent-heuristic", "internal" }
o.shortmess:append("c")

-- Ensure default runtime for colorschemes
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

vim.api.nvim_create_autocmd({ "BufEnter", "DirChanged" }, { callback = update_branch })
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
vim.diagnostic.config { virtual_text = { prefix = ">" }, float = { border = "rounded", source = true } }
map("n", "[e", function() vim.diagnostic.goto_prev { severity = vim.diagnostic.severity.ERROR } end)
map("n", "]e", function() vim.diagnostic.goto_next { severity = vim.diagnostic.severity.ERROR } end)

-- Completion
local function smart_trigger()
    local line = vim.fn.getline('.')
    local col = vim.fn.col('.')
    local before = line:sub(1, col - 1)
    if before:match("[%./~]$") or before:match("/[%w%._%-]*$") then return "<C-x><C-f>"
    elseif vim.bo.omnifunc ~= "" then return "<C-x><C-o>"
    else return "<C-n>" end
end

map("i", "<Tab>", function()
    if vim.fn.pumvisible() == 1 then return "<C-n>" end
    local col = vim.fn.col(".") - 1
    if col == 0 or vim.fn.getline("."):sub(col, col):match("%s") then return "<Tab>" end
    return smart_trigger()
end, { expr = true })
map("i", "<S-Tab>", function() return vim.fn.pumvisible() == 1 and "<C-p>" or "<S-Tab>" end, { expr = true })
map("i", "<cr>", function() return vim.fn.pumvisible() == 1 and "<c-y>" or "<cr>" end, { expr = true })

-- Auto-completion toggle
local auto_cmp = false
local auto_cmp_group = vim.api.nvim_create_augroup("AutoCmp", { clear = true })
local timer = vim.loop.new_timer()
map("n", "<F2>", function()
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

map("n", "<F3>", function()
    o.number, o.relativenumber = not o.number:get(), not o.relativenumber:get()
    print("Line numbers: " .. (o.number:get() and "ON" or "OFF"))
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
    callback = function(ev) map("n", "q", smart_close, { buffer = ev.buf, nowait = true, silent = true }) end,
})
vim.api.nvim_create_autocmd("TermOpen", {
    group = smart_logic,
    callback = function(ev) map("n", "q", smart_close, { buffer = ev.buf, nowait = true, silent = true }) end,
})

map("n", "<Esc>", function() vim.cmd("noh"); smart_close() end, { desc = "Clear highlights and smart close", silent = true })
map("i", "jk", "<Esc>")

-- Netrw navigation
map("n", "-", function()
    if vim.bo.filetype == "netrw" then return vim.cmd("normal -") end
    pcall(vim.cmd, "Explore %:p:h")
end)

map("n", "<leader>e", function()
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

-- File finders
local function ui_sel(items, prompt, on_choice)
    if #items == 0 then return print("None found") end
    vim.ui.select(items, {prompt = prompt }, function(c) if c then on_choice(c) end end)
end

map("n", "<leader>ff", function()
    local pattern = vim.fn.input("Find file: ")
    if pattern == "" then return end
    local cmd = vim.fn.executable("fd") == 1 and "fd -tf -H -E.git " .. vim.fn.shellescape(pattern)
                or "find . -type f ! -path '*/.git/*' -name " .. vim.fn.shellescape("*" .. pattern .. "*")
    local files = vim.fn.systemlist(cmd)
    if #files == 0 or (files[1] and files[1]:match("^error")) then return print("No files found") end
    local qf = {}
    for _, f in ipairs(files) do table.insert(qf, { filename = f, text = f }) end
    vim.fn.setqflist(qf, "r")
    vim.fn.setqflist({}, "a", { title = "Find: " .. pattern })
    vim.cmd("copen")
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
-- GIT INTEGRATION
-- ══════════════════════════════════════════════════════════════════════════════
if vim.fn.executable("git") == 1 then
    local git_ns = vim.api.nvim_create_namespace("git")
    local cache = {}
    local diff_bufs = {}
    local timers = {}
    local diff_mode = "all"

    local function git(cmd, stdin)
        local out = stdin and vim.fn.system(cmd, stdin) or vim.fn.system(cmd)
        return vim.v.shell_error == 0 and out or nil
    end

    local function git_lines(cmd)
        local out = vim.fn.systemlist(cmd)
        return vim.v.shell_error == 0 and out or {}
    end

    local function get_rel_path(buf)
        local name = vim.api.nvim_buf_get_name(buf or 0)
        if name == "" or vim.bo[buf or 0].buftype ~= "" then return nil end
        local rel = git_lines("git ls-files --full-name " .. vim.fn.shellescape(name))[1]
        return (rel and rel ~= "") and rel or nil
    end

    local function get_escaped_path(buf)
        return vim.fn.shellescape(vim.api.nvim_buf_get_name(buf or 0))
    end

    local function refresh_cache(buf)
        buf = buf or vim.api.nvim_get_current_buf()
        if not vim.api.nvim_buf_is_valid(buf) then return nil end
        local rel = get_rel_path(buf)
        if not rel then cache[buf] = nil; return nil end
        cache[buf] = {
            head = git("git show HEAD:" .. vim.fn.shellescape(rel)) or "",
            index = git("git show :0:" .. vim.fn.shellescape(rel)) or "",
        }
        return cache[buf]
    end

    -- Sign metadata with Claude-style colors
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

        -- Map unstaged changes
        for _, h in ipairs(unstaged_diffs) do
            local old_n, new_start, new_n = h[2], h[3], h[4]
            local t = old_n == 0 and "add" or new_n == 0 and "del" or "change"
            local start_l = (t == "del" and new_start == 0) and 1 or math.max(1, new_start)
            for l = start_l, start_l + math.max(new_n - 1, 0) do
                if l <= #lines then signs[l] = { u = t } end
            end
        end

        -- Map staged changes with coordinate shift
        for _, s in ipairs(staged_diffs) do
            local s_old_n, s_new_start, s_new_n = s[2], s[3], s[4]
            local t = s_old_n == 0 and "add" or s_new_n == 0 and "del" or "change"
            local shifted_start = s_new_start
            for _, u in ipairs(unstaged_diffs) do
                if u[1] < s_new_start then
                    shifted_start = shifted_start + (u[4] - u[2])
                end
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
            vim.api.nvim_buf_set_extmark(buf, git_ns, l - 1, 0, {
                sign_text = meta.text,
                sign_hl_group = meta.hl,
                priority = 100,
            })
        end
    end

    -- Hunk operations
    local function parse_hunks(diff_output, rel)
        local hunks = {}
        local i = 1
        while i <= #diff_output do
            local line = diff_output[i]
            local os, oc, ns, nc = line:match("^@@%s*%-(%d+),?(%d*)%s*%+(%d+),?(%d*)%s*@@")
            if os then
                local content = { line }
                i = i + 1
                while i <= #diff_output and not diff_output[i]:match("^@@") do
                    table.insert(content, diff_output[i])
                    i = i + 1
                end
                table.insert(hunks, {
                    old_start = tonumber(os), old_count = tonumber(oc ~= "" and oc or 1),
                    new_start = tonumber(ns), new_count = tonumber(nc ~= "" and nc or 1),
                    lines = content, rel = rel,
                })
            else i = i + 1 end
        end
        return hunks
    end

    local function get_hunks_from_git(mode)
        local rel = get_rel_path()
        if not rel then return {} end
        local cmd = mode == "staged" and "git diff --cached -U0 -- "
                    or mode == "unstaged" and "git diff -U0 -- "
                    or "git diff HEAD -U0 -- "
        return parse_hunks(git_lines(cmd .. get_escaped_path()), rel)
    end

    local function find_hunk_at_cursor(hunks)
        local cur = vim.api.nvim_win_get_cursor(0)[1]
        for _, h in ipairs(hunks) do
            if cur >= h.new_start and cur <= h.new_start + math.max(h.new_count - 1, 0) then
                return h
            end
        end
    end

    local function index_to_buffer_line(index_line, unstaged_hunks)
        local offset = 0
        for _, h in ipairs(unstaged_hunks) do
            if h.old_start + h.old_count <= index_line then
                offset = offset + (h.new_count - h.old_count)
            elseif h.old_start <= index_line then
                return h.new_start
            end
        end
        return index_line + offset
    end

    local function find_staged_hunk_at_cursor(staged_hunks, unstaged_hunks)
        local cur = vim.api.nvim_win_get_cursor(0)[1]
        for _, h in ipairs(staged_hunks) do
            local buf_start = index_to_buffer_line(h.new_start, unstaged_hunks)
            local buf_end = index_to_buffer_line(h.new_start + math.max(h.new_count - 1, 0), unstaged_hunks)
            if cur >= buf_start and cur <= buf_end then return h end
        end
    end

    local function make_patch(hunk, reverse)
        local p = { "--- a/" .. hunk.rel, "+++ b/" .. hunk.rel }
        for _, line in ipairs(hunk.lines) do
            if reverse then
                if line:match("^%+") and not line:match("^%+%+%+") then
                    line = "-" .. line:sub(2)
                elseif line:match("^%-") and not line:match("^%-%-%-") then
                    line = "+" .. line:sub(2)
                elseif line:match("^@@") then
                    line = string.format("@@ -%d,%d +%d,%d @@", hunk.new_start, hunk.new_count, hunk.old_start, hunk.old_count)
                end
            end
            table.insert(p, line)
        end
        return table.concat(p, "\n") .. "\n"
    end

    local function apply_patch(patch, to_index)
        local cmd = "git apply --unidiff-zero" .. (to_index and " --cached" or "")
        return git(cmd .. " -", patch) ~= nil
    end

    local function refresh(buf, reload)
        buf = buf or vim.api.nvim_get_current_buf()
        if reload then vim.cmd("e!") end
        refresh_cache(buf)
        update_signs(buf)
        local d = diff_bufs[buf]
        if d and vim.api.nvim_buf_is_valid(d.buf) then
            local rel = get_rel_path(buf)
            if rel then
                local ref = diff_mode == "all" and "HEAD" or ":0"
                local content = git_lines("git show " .. ref .. ":" .. rel)
                vim.bo[d.buf].modifiable = true
                vim.api.nvim_buf_set_lines(d.buf, 0, -1, false, content)
                vim.bo[d.buf].modifiable = false
            end
        end
    end

    local function debounced_refresh(buf)
        if timers[buf] then vim.fn.timer_stop(timers[buf]) end
        timers[buf] = vim.fn.timer_start(150, function()
            timers[buf] = nil
            vim.schedule(function()
                if vim.api.nvim_buf_is_valid(buf) then update_signs(buf) end
            end)
        end)
    end

    vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "FocusGained" }, { callback = function(ev) refresh(ev.buf) end })
    vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, { callback = function(ev) debounced_refresh(ev.buf) end })
    vim.api.nvim_create_autocmd("BufDelete", {
        callback = function(ev)
            cache[ev.buf] = nil
            diff_bufs[ev.buf] = nil
            if timers[ev.buf] then vim.fn.timer_stop(timers[ev.buf]) end
        end
    })

    -- Claude-style diff colors (brighter, more visible)
    local function setup_highlights()
        -- Signs: subtle, modern colors
        vim.api.nvim_set_hl(0, "GitSignAdd", { fg = "#3fb950" })
        vim.api.nvim_set_hl(0, "GitSignChange", { fg = "#d29922" })
        vim.api.nvim_set_hl(0, "GitSignDelete", { fg = "#f85149" })
        vim.api.nvim_set_hl(0, "GitSignAddStaged", { fg = "#2d5a3d" })
        vim.api.nvim_set_hl(0, "GitSignChangeStaged", { fg = "#6b5416" })
        vim.api.nvim_set_hl(0, "GitSignDeleteStaged", { fg = "#6b2020" })
        vim.api.nvim_set_hl(0, "GitSignAddBoth", { fg = "#3fb950", bg = "#1a4d2e" })
        vim.api.nvim_set_hl(0, "GitSignChangeBoth", { fg = "#d29922", bg = "#6b5416" })
        vim.api.nvim_set_hl(0, "GitSignDeleteBoth", { fg = "#f85149", bg = "#6b2020" })
        -- Diff: Brighter, more visible backgrounds
        vim.api.nvim_set_hl(0, "DiffAdd", { bg = "#234d35", fg = "NONE" })
        vim.api.nvim_set_hl(0, "DiffChange", { bg = "#3d3d20", fg = "NONE" })
        vim.api.nvim_set_hl(0, "DiffDelete", { bg = "#4d2626", fg = "#8b4040", bold = true })
        vim.api.nvim_set_hl(0, "DiffText", { bg = "#5a4d28", fg = "NONE", bold = true })
    end
    setup_highlights()
    vim.api.nvim_create_autocmd("ColorScheme", { callback = setup_highlights })

    -- Hunk operations
    map("n", "<leader>ha", function()
        if vim.bo.modified then vim.cmd("silent write") end
        local h = find_hunk_at_cursor(get_hunks_from_git("unstaged"))
        if not h then return print("No unstaged hunk at cursor") end
        if apply_patch(make_patch(h, false), true) then refresh(); print("Staged hunk") else print("Failed") end
    end)

    map("n", "<leader>hu", function()
        if vim.bo.modified then vim.cmd("silent write") end
        local staged = get_hunks_from_git("staged")
        local h = find_staged_hunk_at_cursor(staged, get_hunks_from_git("unstaged"))
        if not h then return print("No staged hunk at cursor") end
        if apply_patch(make_patch(h, true), true) then refresh(); print("Unstaged hunk") else print("Failed") end
    end)

    map("n", "<leader>hr", function()
        if vim.bo.modified then vim.cmd("silent write") end
        local h = find_hunk_at_cursor(get_hunks_from_git("unstaged"))
        if not h then return print("No unstaged hunk at cursor") end
        if apply_patch(make_patch(h, true), false) then refresh(nil, true); print("Reset hunk") else print("Failed") end
    end)

    -- Hunk navigation
    map("n", "]c", function()
        if vim.bo.modified then vim.cmd("silent write") end
        local hunks = get_hunks_from_git(diff_mode == "all" and "all" or "unstaged")
        local cur = vim.api.nvim_win_get_cursor(0)[1]
        for _, h in ipairs(hunks) do
            if h.new_start > cur then
                vim.api.nvim_win_set_cursor(0, { h.new_start, 0 })
                return
            end
        end
        print("No more hunks")
    end)

    map("n", "[c", function()
        if vim.bo.modified then vim.cmd("silent write") end
        local hunks = get_hunks_from_git(diff_mode == "all" and "all" or "unstaged")
        local cur = vim.api.nvim_win_get_cursor(0)[1]
        for i = #hunks, 1, -1 do
            if hunks[i].new_start < cur then
                vim.api.nvim_win_set_cursor(0, { hunks[i].new_start, 0 })
                return
            end
        end
        print("No more hunks")
    end)

    map("n", "<leader>gm", function()
        diff_mode = diff_mode == "all" and "unstaged" or "all"
        refresh()
        print("Diff mode: " .. (diff_mode == "all" and "All changes (HEAD)" or "Unstaged only (INDEX)"))
    end)

    -- Diff views
    local diff_syntax_enabled = true  -- Track syntax highlighting state

    local function close_diff_view()
        for _, win in ipairs(vim.api.nvim_list_wins()) do
            local b = vim.api.nvim_win_get_buf(win)
            if vim.b[b].is_git_diff then pcall(vim.api.nvim_win_close, win, true) end
        end
        vim.cmd("diffoff!")
        diff_bufs = {}
    end

    -- Split diff (gd) - keeps original file as working buffer
    map("n", "<leader>gd", function()
        local rel = get_rel_path()
        if not rel then return print("Not tracked") end

        -- Check for 3-way merge conflict
        local ours = git_lines("git show :2:" .. rel)
        local theirs = git_lines("git show :3:" .. rel)
        if #ours > 0 and #theirs > 0 then
            vim.cmd("tabnew " .. vim.fn.fnameescape(vim.api.nvim_buf_get_name(0)))
            local work_buf = vim.api.nvim_get_current_buf()
            vim.cmd("diffthis")

            vim.cmd("leftabove vnew")
            vim.api.nvim_buf_set_lines(0, 0, -1, false, ours)
            vim.bo.buftype, vim.bo.bufhidden, vim.bo.modifiable = "nofile", "wipe", false
            vim.b.is_git_diff = true
            vim.cmd("diffthis")
            local ours_buf = vim.api.nvim_get_current_buf()

            vim.cmd("wincmd l | rightbelow vnew")
            vim.api.nvim_buf_set_lines(0, 0, -1, false, theirs)
            vim.bo.buftype, vim.bo.bufhidden, vim.bo.modifiable = "nofile", "wipe", false
            vim.b.is_git_diff = true
            vim.cmd("diffthis")
            local theirs_buf = vim.api.nvim_get_current_buf()

            vim.api.nvim_set_current_win(vim.fn.win_findbuf(work_buf)[1])
            setup_highlights()
            map("n", "gh", "<cmd>diffget " .. ours_buf .. "<cr>", { buffer = work_buf })
            map("n", "gl", "<cmd>diffget " .. theirs_buf .. "<cr>", { buffer = work_buf })
            map("n", "q", "<cmd>tabclose<cr>", { buffer = work_buf })
            return print("3-way: OURS|WORK|THEIRS (gh/gl=get q=quit)")
        end

        -- Normal 2-way diff: REF (left) | WORKING (right)
        local ref = diff_mode == "all" and "HEAD" or ":0"
        local label = diff_mode == "all" and "HEAD" or "INDEX"
        local content = git_lines("git show " .. ref .. ":" .. rel)
        if #content == 0 then return print("No " .. label) end

        local work_buf = vim.api.nvim_get_current_buf()
        vim.cmd("vnew")
        local ref_buf = vim.api.nvim_get_current_buf()
        vim.api.nvim_buf_set_lines(ref_buf, 0, -1, false, content)
        vim.bo[ref_buf].buftype = "nofile"
        vim.bo[ref_buf].bufhidden = "wipe"
        vim.bo[ref_buf].modifiable = false
        vim.b[ref_buf].is_git_diff = true
        if diff_syntax_enabled then vim.bo[ref_buf].filetype = vim.bo[work_buf].filetype end
        vim.cmd("diffthis")
        vim.wo.foldcolumn = "0"

        diff_bufs[work_buf] = { buf = ref_buf, win = vim.api.nvim_get_current_win(), ref = ref }

        vim.cmd("wincmd p | diffthis")
        setup_highlights()

        map("n", "q", close_diff_view, { buffer = work_buf })
        map("n", "q", close_diff_view, { buffer = ref_buf })

        -- Toggle syntax highlighting
        map("n", "ts", function()
            diff_syntax_enabled = not diff_syntax_enabled
            vim.bo[ref_buf].filetype = diff_syntax_enabled and vim.bo[work_buf].filetype or ""
            print("Diff syntax: " .. (diff_syntax_enabled and "ON" or "OFF"))
        end, { buffer = work_buf })

        print("Diff: " .. label .. " | WORKING (]c/[c nav, ts=toggle syntax, q=quit)")
    end)

    map("n", "<leader>gD", function()
        local rel = get_rel_path()
        if not rel then return print("Not tracked") end
        local cmd = diff_mode == "all" and "git diff HEAD -- " or "git diff -- "
        local diff = git_lines(cmd .. get_escaped_path())
        if #diff == 0 then return print("No changes") end
        vim.cmd("tabnew")
        vim.api.nvim_buf_set_lines(0, 0, -1, false, diff)
        vim.bo.buftype = "nofile"
        vim.bo.bufhidden = "wipe"
        vim.bo.filetype = "diff"
        map("n", "q", "<cmd>tabclose<cr>", { buffer = true })
        print("Unified diff (" .. (diff_mode == "all" and "all changes" or "unstaged") .. ") q=quit")
    end)

    -- File operations
    map("n", "<leader>ga", function()
        if not git("git add " .. get_escaped_path()) then return print("Failed") end
        refresh(); print("Staged file")
    end)

    map("n", "<leader>gu", function()
        if not git("git restore --staged " .. get_escaped_path()) then return print("Failed") end
        refresh(); print("Unstaged file")
    end)

    map("n", "<leader>gr", function()
        if not git("git restore " .. get_escaped_path()) then return print("Failed") end
        refresh(nil, true); print("Reset file")
    end)

    map("n", "<leader>gs", function()
        local status = git_lines("git status --porcelain")
        if #status == 0 then return print("Clean") end
        local qf = {}
        for _, line in ipairs(status) do table.insert(qf, { filename = line:sub(4), text = line:sub(1, 2) }) end
        vim.fn.setqflist(qf, "r")
        vim.fn.setqflist({}, "a", { title = "Git Status" })
        vim.cmd("copen")
    end)

    map("n", "<leader>gb", function()
        local blame = git_lines("git blame --date=short " .. get_escaped_path())
        if #blame == 0 then return print("Not tracked") end
        vim.cmd("tabnew")
        vim.api.nvim_buf_set_lines(0, 0, -1, false, blame)
        vim.bo.buftype = "nofile"
        vim.bo.bufhidden = "wipe"
        map("n", "q", "<cmd>tabclose<cr>", { buffer = true })
        print("Blame (q quit)")
    end)

    map("n", "<leader>gl", function()
        local file = vim.api.nvim_buf_get_name(0)
        local rel = get_rel_path()
        if not rel then return print("Not tracked") end
        local filetype = vim.bo.filetype
        local log = git_lines("git log --oneline -50 -- " .. get_escaped_path())
        if #log == 0 then return print("No history") end
        local qf = {}
        for _, line in ipairs(log) do
            local hash, msg = line:match("^(%S+)%s+(.*)$")
            if hash then table.insert(qf, { filename = file, text = hash .. " " .. msg, user_data = hash }) end
        end
        vim.fn.setqflist(qf, "r")
        vim.fn.setqflist({}, "a", { title = "Git Log: " .. vim.fn.fnamemodify(file, ":t") })
        vim.cmd("copen")

        -- Set up keymaps after qf window opens
        vim.schedule(function()
            local qf_buf = vim.fn.bufnr()
            if vim.bo[qf_buf].filetype == "qf" then
                -- Enter: side-by-side diff view
                map("n", "<CR>", function()
                    local item = vim.fn.getqflist()[vim.fn.line(".")]
                    if not item or not item.user_data then return end
                    local hash = item.user_data
                    local old_content = git_lines("git show " .. hash .. "~1:" .. vim.fn.shellescape(rel))
                    local new_content = git_lines("git show " .. hash .. ":" .. vim.fn.shellescape(rel))
                    if #new_content == 0 then return print("No content") end

                    vim.cmd("tabnew")
                    local work_buf = vim.api.nvim_get_current_buf()
                    vim.api.nvim_buf_set_lines(work_buf, 0, -1, false, new_content)
                    if diff_syntax_enabled then vim.bo[work_buf].filetype = filetype end
                    vim.bo[work_buf].buftype = "nofile"
                    vim.bo[work_buf].bufhidden = "wipe"

                    vim.cmd("leftabove vnew")
                    local old_buf = vim.api.nvim_get_current_buf()
                    vim.api.nvim_buf_set_lines(old_buf, 0, -1, false, old_content)
                    vim.bo[old_buf].buftype = "nofile"
                    vim.bo[old_buf].bufhidden = "wipe"
                    vim.bo[old_buf].modifiable = false
                    if diff_syntax_enabled then vim.bo[old_buf].filetype = filetype end
                    vim.cmd("diffthis")
                    vim.wo.foldcolumn = "0"

                    vim.cmd("wincmd p | diffthis")
                    setup_highlights()

                    map("n", "q", "<cmd>tabclose<cr>", { buffer = work_buf })
                    map("n", "q", "<cmd>tabclose<cr>", { buffer = old_buf })
                    map("n", "ts", function()
                        diff_syntax_enabled = not diff_syntax_enabled
                        vim.bo[old_buf].filetype = diff_syntax_enabled and filetype or ""
                        vim.bo[work_buf].filetype = diff_syntax_enabled and filetype or ""
                        print("Diff syntax: " .. (diff_syntax_enabled and "ON" or "OFF"))
                    end, { buffer = work_buf })

                    print("Commit " .. hash .. " - ts=toggle syntax, q=quit")
                end, { buffer = qf_buf })

                -- u: unified diff
                map("n", "u", function()
                    local item = vim.fn.getqflist()[vim.fn.line(".")]
                    if not item or not item.user_data then return end
                    local diff = git_lines("git show --stat --patch " .. item.user_data .. " -- " .. vim.fn.shellescape(rel))
                    if #diff == 0 then return print("No diff") end
                    vim.cmd("tabnew")
                    vim.api.nvim_buf_set_lines(0, 0, -1, false, diff)
                    vim.bo.buftype = "nofile"
                    vim.bo.bufhidden = "wipe"
                    vim.bo.filetype = "diff"
                    map("n", "q", "<cmd>tabclose<cr>", { buffer = true })
                end, { buffer = qf_buf })
            end
        end)

        print("Log: Enter=diff view, u=unified, q=close")
    end)

    map("n", "<leader>gC", "<cmd>terminal git commit<cr>")
    map("n", "<leader>gP", "<cmd>!git push<cr>")

    -- Conflict resolution
    local function resolve_conflict(choice)
        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
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

        local ranges = { ours = { s + 1, (m or e) - 1 }, theirs = { e + 1, f - 1 }, base = m and { m + 1, e - 1 } }
        local range = ranges[choice]
        if not range then return print("No base section") end

        local result = {}
        for i = range[1], range[2] do table.insert(result, lines[i]) end
        vim.api.nvim_buf_set_lines(0, s - 1, f, false, result)
        print("Resolved: " .. choice .. " (" .. #result .. " lines)")
    end

    map("n", "gH", function() resolve_conflict("ours") end)
    map("n", "gJ", function() resolve_conflict("base") end)
    map("n", "gL", function() resolve_conflict("theirs") end)

    map("n", "<leader>gp", function()
        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
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

        local preview = { "=== CONFLICT PREVIEW ===" }
        table.insert(preview, "")
        table.insert(preview, "OURS (gH):")
        for i = s + 1, (m or e) - 1 do table.insert(preview, "  " .. lines[i]) end

        if m then
            table.insert(preview, "")
            table.insert(preview, "BASE (gJ):")
            for i = m + 1, e - 1 do table.insert(preview, "  " .. lines[i]) end
        end

        table.insert(preview, "")
        table.insert(preview, "THEIRS (gL):")
        for i = e + 1, f - 1 do table.insert(preview, "  " .. lines[i]) end

        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_open_win(buf, true, {
            relative = "cursor", row = 1, col = 0,
            width = math.min(80, vim.o.columns - 4),
            height = math.min(#preview + 2, 20),
            style = "minimal", border = "rounded",
        })
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, preview)
        vim.bo[buf].buftype = "nofile"
        vim.bo[buf].modifiable = false
        map("n", "q", "<cmd>close<cr>", { buffer = buf })
    end)

    -- :G command with auto-refresh
    vim.api.nvim_create_user_command("G", function(opts)
        vim.cmd("terminal git " .. table.concat(opts.fargs, " "))
        vim.b.is_git_terminal = true
    end, { nargs = "+", complete = "shellcmd" })

    vim.api.nvim_create_autocmd("TermClose", {
        callback = function(ev)
            if vim.b[ev.buf].is_git_terminal then
                vim.schedule(function()
                    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                        if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == "" then
                            refresh(buf)
                        end
                    end
                    vim.cmd("bd!")
                end)
            else
                vim.schedule(function() vim.cmd("bd!") end)
            end
        end
    })
end

-- Tmux integration
local function nvim_tmux_nav(direction)
    local win = vim.api.nvim_get_current_win()
    vim.cmd('wincmd ' .. direction)
    if win == vim.api.nvim_get_current_win() then
        local tmux_dir = {h = 'L', j = 'D', k = 'U', l = 'R'}
        vim.fn.system('tmux select-pane -' .. tmux_dir[direction])
    end
end

map('n', '<C-h>', function() nvim_tmux_nav('h') end)
map('n', '<C-j>', function() nvim_tmux_nav('j') end)
map('n', '<C-k>', function() nvim_tmux_nav('k') end)
map('n', '<C-l>', function() nvim_tmux_nav('l') end)

-- Core keymaps
map("n", "<leader>w", "<cmd>w<cr>")
map("n", "<leader>q", "<cmd>q<cr>")
map("n", "<leader>Q", "<cmd>qa<cr>")
map("n", "Q", function()
    for _, win in ipairs(vim.fn.getwininfo()) do
        if win.quickfix == 1 then vim.cmd("cclose"); return end
    end
    if vim.fn.empty(vim.fn.getqflist()) == 1 then print("Quickfix empty") else vim.cmd("copen") end
end)

map("n", "<Tab>", "<cmd>bn<cr>")
map("n", "<S-Tab>", "<cmd>bp<cr>")
map("n", "<leader>bd", "<cmd>bd<cr>")
map("n", "<leader>t", "<cmd>term<cr>")
map("t", "<Esc><Esc>", "<C-\\><C-n>")
map({ "n", "v" }, "<leader>y", '"+y')
map({ "n", "v" }, "<leader>p", '"+p')
map("v", "<", "<gv")
map("v", ">", ">gv")
map("v", "<A-j>", ":m '>+1<cr>gv=gv")
map("v", "<A-k>", ":m '<-2<cr>gv=gv")
map("n", "[q", "<cmd>cprev<cr>")
map("n", "]q", "<cmd>cnext<cr>")

map("n", "<leader>cc", function() vim.cmd("e " .. vim.fn.stdpath("config") .. "/init_minimal.lua") end)
map("n", "<leader>cr", function()
    for _, group in ipairs(vim.api.nvim_get_autocmds({})) do
        if group.group_name and not group.group_name:match("^nvim") then
            pcall(vim.api.nvim_del_augroup_by_name, group.group_name)
        end
    end
    dofile(vim.fn.stdpath("config") .. "/init_minimal.lua")
    print("Config reloaded")
end)

map("n", "<leader>cd", function()
    local git_root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
    if vim.v.shell_error == 0 and git_root then
        vim.cmd("cd " .. vim.fn.fnameescape(git_root))
    else
        vim.cmd("cd %:p:h")
    end
    print("CWD: " .. vim.fn.getcwd())
end)

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
        if vim.api.nvim_buf_is_loaded(b) and not visible[b] and vim.bo[b].buftype == "" then
            pcall(vim.api.nvim_buf_delete, b, {})
            closed = closed + 1
        end
    end
    print("Closed " .. closed .. " hidden buffers")
end)

-- Autocommands
vim.api.nvim_create_autocmd("TextYankPost", { callback = function() vim.highlight.on_yank() end })
vim.api.nvim_create_autocmd("BufReadPost", { callback = function()
    local m = vim.api.nvim_buf_get_mark(0, '"')
    if m[1] > 0 and m[1] <= vim.api.nvim_buf_line_count(0) then pcall(vim.api.nvim_win_set_cursor, 0, m) end
end })

-- Help
map("n", "<leader>?", function()
    print([[
    CUSTOM:   w/q/Q save/quit/toggle-qf | ff/fr/fb/fg find | e/- explore | y/p clip | bd/bo buf | Tab nav | C-hjkl win
    r replace | R run | cc/cr config/reload | F2 auto-cmp | F3 numbers | sw strip | st tab | cd git-root
    NETRW:    - vinegar(up) | e toggle-sidebar | h/l nav | ./q hidden/quit | a/A file/dir | r rename | dd del | P preview
    GIT DIFF: gd split | gD unified | gm mode(all/unstaged) | ts=syntax | q=quit
    GIT NAV:  ]c/[c hunk | ]e/[e errors | ]q/[q quickfix
    GIT FILE: gs status | ga/gu stage/unstage | gr reset
    GIT VIEW: gp conflict-preview | gC commit | gP push | gb blame | gl log(CR=diff u=unified)
    HUNK OPS: ha/hu stage/unstage-hunk | hr reset-hunk
    CONFLICT: gH/gJ/gL resolve(ours/base/theirs) | gh/gl diffget in 3-way
    LSP/DIAG: gd/gD/grr/gri/K/grn/gra LSP | gry/grf type/format
    GIT GUTTER: green=add orange=change red=delete | bright=unstaged dim=staged bg=both]])
end)
