-- init.lua — yazi startup hooks.
--
-- Activates the vendored git plugin (plugins/git.yazi) so each file in the
-- listing shows its git status. The plugin is committed into this repo rather
-- than installed with `ya pack`, so it ships with the config over the existing
-- ~/.config/yazi symlink — no network, nothing to fetch on a fresh machine.
--
-- The status SIGNS are overridden to plain ASCII in theme.toml ([git]); the
-- plugin's built-in defaults are Nerd Font glyphs, which would show as tofu on
-- a terminal without the font (same reason theme.toml disables file icons).

require("git"):setup()

-- plugins/split-tabs.yazi — dual-pane view, also vendored rather than fetched
-- with `ya pkg add`, same reason as above. Upstream is terrakok/split-tabs.yazi
-- pinned at d0531f495030; it declares `@since 26.5.6`, which is exactly the yazi
-- version vendored here, so re-check that line before bumping either one.
--
-- Nothing to call at startup: the plugin exposes a `spl_activate` action that
-- would open in split mode, but it is deliberately not used — the point is the
-- runtime toggle on `\` (see keymap.toml). yazi starts single-pane as always.
