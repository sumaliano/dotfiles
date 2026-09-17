-- nvim-treesitter (main) compiles every parser by shelling out to the
-- tree-sitter CLI, and LazyVim installs that CLI through Mason when it's
-- missing. Mason only downloads the upstream prebuilt binary, and from 0.26.1
-- upstream builds it on Ubuntu 24.04 — it needs glibc 2.39 and won't even
-- exec on older systems (RHEL 9 is 2.34). Upstream calls that wontfix
-- (tree-sitter/tree-sitter#4174), so LazyVim's "just works" breaks there.
--
-- Every parser install/update in LazyVim funnels through
-- LazyVim.treesitter.ensure_treesitter_cli, so wrap that: let LazyVim do its
-- usual thing, then if the CLI it ended up with can't run here, reinstall the
-- last release built on Ubuntu 22.04 (glibc >= 2.34) before handing back.
-- Modern machines never hit the fallback. `:checkhealth nvim-treesitter`
-- still flags the pinned CLI as too old; that check is a report, not a gate —
-- install.lua only ever runs `tree-sitter build`, which 0.25.10 has.
local PORTABLE_CLI = "v0.25.10"

local function cli_runs()
    return vim.fn.executable("tree-sitter") == 1 and vim.system({ "tree-sitter", "--version" }):wait().code == 0
end

local function patch()
    local ts = LazyVim.treesitter
    if ts._portable_cli then
        return
    end
    ts._portable_cli = true
    local ensure = ts.ensure_treesitter_cli
    ts.ensure_treesitter_cli = function(cb)
        ensure(function(ok, err)
            if not ok or cli_runs() then
                return cb(ok, err)
            end
            local pkg = require("mason-registry").get_package("tree-sitter-cli")
            local function done(success)
                if success then
                    cb(true)
                else
                    cb(false, "Failed to install `tree-sitter-cli@" .. PORTABLE_CLI .. "` with `mason.nvim`.")
                end
            end
            -- LazyVim's config and its build hook can both land here at once;
            -- let the first one drive Mason and have the other wait on it.
            if pkg:is_installing() then
                pkg:once("install:success", vim.schedule_wrap(function() done(cli_runs()) end))
                pkg:once("install:failed", vim.schedule_wrap(function() done(false) end))
                return
            end
            LazyVim.warn("tree-sitter CLI can't run on this glibc — pinning Mason's `tree-sitter-cli` to " .. PORTABLE_CLI)
            pkg:install({ version = PORTABLE_CLI }, vim.schedule_wrap(done))
        end)
    end
end

return {
    {
        "nvim-treesitter/nvim-treesitter",
        -- `opts` runs right before LazyVim's config on every load, including
        -- under `:Lazy build`; returning nothing leaves the merged opts as-is.
        opts = function()
            patch()
        end,
    },
}
