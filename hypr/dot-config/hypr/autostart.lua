-- Extra autostart processes.
-- o.launch_on_start("my-service")
o.launch_on_start("omarchy-video-idle-inhibitor")

-- No lock screen is used, so this independently powers the display off after
-- 5 minutes idle (and back on on activity) to save energy.
o.launch_on_start([[swayidle -w timeout 300 'omarchy-brightness-display off' resume 'omarchy-brightness-display on']])
