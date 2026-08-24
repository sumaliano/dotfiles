-- init.lua — yazi startup hooks.
--
-- Both plugins here are committed into this repo rather than installed with
-- `ya pkg add`, so they ship with the config over the existing ~/.config/yazi
-- symlink — no network, nothing to fetch on a fresh machine. The cost is that
-- each one is pinned to a yazi version, so they must be bumped together with
-- the vendored binary; both pins are recorded below.

-- plugins/git.yazi — shows each file's git status in the linemode. Pinned at
-- 044c3cc290a2 (declares `@since 26.8.15`, matching the vendored yazi).
--
-- The pairing matters more than it looks: this plugin talks to yazi's fetcher
-- API, which changed during the 26.5.6 line. Running a newer plugin against an
-- older binary made every fetch fail with "error converting Lua boolean to
-- function", which surfaced only as "unfinished tasks" on quit and silently
-- stale git signs. If that prompt ever comes back, check this pin against
-- `yazi --version` first.
require("git"):setup { order = 1500 }

-- plugins/split-tabs.yazi — dual-pane view. Pinned at d0531f495030.
--
-- Nothing to call at startup: the plugin exposes a `spl_activate` action that
-- would open in split mode, but it is deliberately not used — the point is the
-- runtime toggle on `\` (see keymap.toml). yazi starts single-pane as always.

-- There is deliberately no theme.toml. It used to blank out [icon] and rewrite
-- the [git] signs as ASCII, because the font bundled in this repo was a pre-v3
-- Nerd Font missing the glyphs yazi draws. Both blocks silently stopped
-- applying in yazi 26.8 — dead config that still looked live. The font is the
-- real fix (Nerd Fonts v3, see fonts/ and stage_fonts_windows in
-- scripts/install.sh), so yazi now draws its own glyphs and there is nothing
-- here to keep in sync on upgrade.
--
-- If glyphs ever show as tofu boxes again, the terminal font is wrong or is a
-- pre-v3 build — fix that, not this config.
