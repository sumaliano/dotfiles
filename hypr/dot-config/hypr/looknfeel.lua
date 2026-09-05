-- Change the default Omarchy look'n'feel.

-- https://wiki.hypr.land/Configuring/Basics/Variables/#general
hl.config({
  general = {
    -- No gaps between windows or borders.
    gaps_in = 2,
    gaps_out = 0,
    -- border_size = 0,
    --
    -- Change to niri-like side-scrolling layout.
    -- layout = "scrolling",
  },
})

-- https://wiki.hypr.land/Configuring/Basics/Variables/#decoration
hl.config({
  decoration = {
    -- Use round window corners.
    rounding = 10,

    -- Dim unfocused windows (0.0 = no dim, 1.0 = fully dimmed).
    -- dim_inactive = true,
    -- dim_strength = 0.15,
  },
})

-- https://wiki.hypr.land/Configuring/Basics/Variables/#animations
hl.config({
  animations = {
    -- Disable all animations for max speed / lowest resource usage.
    enabled = false,
  },
})

-- Groupbar colors are themed via ~/.config/omarchy/themed/hyprland.lua.tpl
-- (regenerated from colors.toml on every theme change) so they never go
-- stale here. This just closes up the layout gaps around it.
-- https://wiki.hypr.land/Configuring/Variables/#groupbar
hl.config({
  group = {
    groupbar = {
      gaps_in = 0,
      indicator_gap = 0,
      indicator_height = 0,
    },
  },
})

-- Windows default to fully opaque; SUPER+BACKSPACE toggles the `opaque` prop
-- off to reveal this opacity value instead (Omarchy's own stock 0.985/0.96
-- default was too close to 1.0 for that toggle to look like anything).
o.window(".*", { opaque = true, opacity = "0.85 0.85" })

-- Is the widest connected monitor ultrawide-class (aspect ratio >= 2.0, e.g.
-- 21:9+) rather than a standard 16:9 screen (e.g. a laptop panel)? Drives the
-- dwindle single-window aspect ratio and the scrolling column width below,
-- so the same config adapts to whichever machine it loads on. Uses
-- hl.get_monitors() (in-process) rather than shelling out to hyprctl, which
-- deadlocks the IPC when called from inside config evaluation.
local function has_ultrawide_monitor()
  local ok, monitors = pcall(hl.get_monitors)
  if not ok or not monitors then
    return false
  end

  for _, monitor in ipairs(monitors) do
    if monitor.height and monitor.height > 0 and (monitor.width / monitor.height) >= 2.0 then
      return true
    end
  end

  return false
end

-- https://wiki.hypr.land/Configuring/Basics/Variables/#layout
hl.config({
  layout = {
    -- Avoid an overly wide single-window layout on an ultrawide monitor;
    -- {0, 0} leaves a standard 16:9 screen unconstrained (it fills normally).
    single_window_aspect_ratio = has_ultrawide_monitor() and { 1, 1 } or { 0, 0 },
  },
})

-- https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/
-- Fit 3 windows across an ultrawide monitor, 2 across a standard 16:9 one.
hl.config({
  scrolling = {
    column_width = has_ultrawide_monitor() and 1 / 3 or 1 / 2,
  },
})
