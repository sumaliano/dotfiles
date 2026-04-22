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
-- Help menu (Minimal)
vim.keymap.set("n", "<leader>?", function()
    print([[
    GENERAL:  w/q/Q save/quit/toggle-qf | ff/fr/fb/fg find | e/- explore | y/p clip | bd buf | Tab nav | M-hjkl win
    r replace | R run | cc/cr config/reload | F2 auto-cmp | F3 numbers | sw strip | st tab | cd root
    GIT:      gs status | gd diff | ga add | gu unstage | gr restore | ]c/[c hunk
    LSP/DIAG: gry type | grf format | [e/]e error | K hover
    GUTTER:   green=add orange=change red=delete | bright=unstaged dim=staged bg=both]])
end)
