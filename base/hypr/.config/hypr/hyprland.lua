-- Slim Hyprland starter.
--
-- This file deliberately contains only:
--   * one catch-all monitor rule (auto-detect),
--   * one bind to open the terminal,
--   * one bind to close the active window,
--   * one bind to exit Hyprland.
--
-- Machine-specific monitor/input/GPU overrides live in
-- ~/.config/hypr/host.lua, stowed from hosts/<hostname>/.

hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})

local terminal = "kitty"

-- Open the terminal.
hl.bind("SUPER + Return", hl.dsp.exec_cmd(terminal))

-- Close the active window.
hl.bind("SUPER + Q", hl.dsp.window.close())

-- Exit Hyprland.
hl.bind("SUPER + M", hl.dsp.exit())

-- Load optional per-host overrides. The file is only present when
-- ./install.sh stowed a matching hosts/<hostname>/ package.
local hostfile = (os.getenv("HOME") or "") .. "/.config/hypr/host.lua"
local host_handle = io.open(hostfile, "r")
if host_handle then
    host_handle:close()
    dofile(hostfile)
end
