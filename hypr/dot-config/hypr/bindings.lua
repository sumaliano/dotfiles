-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Add a new binding.
-- o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")

-- Change an existing binding by unbinding it first, then binding the key again.
-- This example changes SUPER+SPACE from the launcher to the Omarchy root menu.
-- hl.unbind("SUPER + SPACE")
-- o.bind("SUPER + SPACE", "Omarchy menu", "omarchy-menu toggle root")

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")

-- SUPER+SHIFT+arrow defaults to swapwindow, which only swaps the active
-- window with its neighbor in place. movewindow instead walks the dwindle
-- tree and actually re-inserts the window there, so it can move in and out
-- of split containers rather than just trading places.
hl.unbind("SUPER + SHIFT + LEFT")
hl.unbind("SUPER + SHIFT + RIGHT")
hl.unbind("SUPER + SHIFT + UP")
hl.unbind("SUPER + SHIFT + DOWN")
o.bind("SUPER + SHIFT + LEFT", "Move window left", hl.dsp.window.move({ direction = "l" }))
o.bind("SUPER + SHIFT + RIGHT", "Move window right", hl.dsp.window.move({ direction = "r" }))
o.bind("SUPER + SHIFT + UP", "Move window up", hl.dsp.window.move({ direction = "u" }))
o.bind("SUPER + SHIFT + DOWN", "Move window down", hl.dsp.window.move({ direction = "d" }))

-- Move "Close window" from SUPER+W to SUPER+Q.
hl.unbind("SUPER + W")
o.bind("SUPER + Q", "Close window", hl.dsp.window.close())

-- F11 as an additional fullscreen key, alongside SUPER+F.
o.bind("F11", "Full screen", hl.dsp.window.fullscreen({ mode = "fullscreen" }))

-- Logitech MX Keys examples:
-- o.bind("SUPER + SHIFT + S", nil, "omarchy-capture-screenshot")
-- o.bind("SUPER + H", nil, "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, "omarchy-shell shell toggle omarchy.emojis")
