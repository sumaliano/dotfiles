-- Learn how to configure Hyprland: https://wiki.hypr.land/Configuring/Start/

-- Omarchy's bootstrap keeps path setup out of this user config.
dofile((os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/default/hypr/bootstrap.lua")

-- Disable all Omarchy default bindings. Add your own in hypr/bindings.lua.
-- omarchy_default_bindings = false
--
-- Or disable only bindings for Omarchy's preinstalled apps/web apps while
-- keeping core window-manager bindings:
-- omarchy_preinstalled_bindings = false

-- Load Omarchy defaults.
require("default.hypr.omarchy")

-- Put your personal overrides in these files. They're loaded after Omarchy's
-- defaults so package updates can improve the defaults without rewriting your
-- ~/.config/hypr files.
require("hypr.monitors")
require("hypr.input")
require("hypr.bindings")
require("hypr.looknfeel")
require("hypr.autostart")

-- Toggle config flags dynamically.
require("default.hypr.toggles")

-- Add any other personal Hyprland configuration below.
-- o.window("qemu", { workspace = "5" })

-- Scratchpad (SUPER+S): float windows so they can be moved and resized.
-- `float`/`size`/`center` are static effects (applied when a window maps), so
-- windows moved onto the scratchpad later are floated from the event below.
-- `no_max_size` is dynamic and stays in effect while the window is there, so
-- apps that advertise a max size can still be resized.
local scratchpad = "special:scratchpad"

o.window({ workspace = scratchpad }, {
  float = true,
  center = true,
  size = { "monitor_w*0.75", "monitor_h*0.75" },
  no_max_size = true,
})

local function is_scratchpad(ws)
  return ws ~= nil and ws.name == scratchpad
end

local function float_scratchpad_window(w)
  if w == nil or w.floating then
    return
  end

  hl.dispatch(hl.dsp.window.float({ action = "set", window = w }))

  local m = w.monitor
  if m and m.width and m.height then
    hl.dispatch(hl.dsp.window.resize({
      x = math.floor(m.width * 0.75),
      y = math.floor(m.height * 0.75),
      relative = false,
      window = w,
    }))
  end

  hl.dispatch(hl.dsp.window.center({ window = w }))
end

hl.on("window.move_to_workspace", function(w, ws)
  if is_scratchpad(ws) then
    float_scratchpad_window(w)
  end
end)

local ok, scratchpad_ws = pcall(hl.get_workspace, scratchpad)
if ok and scratchpad_ws then
  local windows_ok, windows = pcall(function()
    return scratchpad_ws:get_windows()
  end)
  if windows_ok and type(windows) == "table" then
    for _, w in ipairs(windows) do
      float_scratchpad_window(w)
    end
  end
end
