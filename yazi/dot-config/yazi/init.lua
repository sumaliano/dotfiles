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
