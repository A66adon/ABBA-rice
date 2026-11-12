-- Hyprland 0.57+ Lua configuration.
-- KDE Plasma is a separate session and is not modified by this file.

local mainMod = "SUPER"
local terminal = "kitty"
local fileManager = "dolphin"
local menu = "wofi --show drun"

----------------
---- MONITORS ----
----------------

-- Layout copied from the current KDE setup. If cables or monitors change,
-- edit these three lines (or remove them to let Hyprland auto-detect).
hl.monitor({ output = "DP-1", mode = "2560x1440@164.96", position = "4480x0", scale = "1" })
hl.monitor({ output = "HDMI-A-2", mode = "2560x1440@59.95", position = "1920x0", scale = "1" })
hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@60.00", position = "0x188", scale = "1" })
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

hl.env("XCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Ice")
-- Let KDE apps use the existing KDE/Breeze look inside Hyprland.
hl.env("QT_QPA_PLATFORMTHEME", "kde")
hl.env("QT_STYLE_OVERRIDE", "Breeze")
hl.env("GTK_THEME", "Adwaita:dark")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
    hl.dispatch(hl.dsp.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"))
    hl.dispatch(hl.dsp.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"))
    hl.dispatch(hl.dsp.exec_cmd("hyprpaper &"))
    hl.dispatch(hl.dsp.exec_cmd("waybar &"))
    hl.dispatch(hl.dsp.exec_cmd("mako &"))
    hl.dispatch(hl.dsp.exec_cmd("hypridle &"))
    hl.dispatch(hl.dsp.exec_cmd("sh -c '~/.config/hypr/scripts/clipboard-watch.sh &'"))
    hl.dispatch(hl.dsp.exec_cmd("sh -c 'command -v nm-applet >/dev/null && nm-applet --indicator &'"))
    hl.dispatch(hl.dsp.exec_cmd("sh -c 'command -v blueman-applet >/dev/null && blueman-applet &'"))
    hl.dispatch(hl.dsp.exec_cmd("sh -c 'if [ -x /usr/lib/hyprpolkitagent ]; then /usr/lib/hyprpolkitagent & else /usr/lib/polkit-kde-authentication-agent-1 & fi'"))
    hl.dispatch(hl.dsp.exec_cmd("sh -c 'command -v hyprctl >/dev/null && hyprctl setcursor Bibata-Modern-Ice 24'"))
end)

-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
    general = {
        gaps_in = 5,
        gaps_out = 12,
        border_size = 2,
        col = {
            active_border = { colors = { "rgba(cba6f7ee)", "rgba(89b4faee)" }, angle = 45 },
            inactive_border = "rgba(45475a88)",
        },
        layout = "dwindle",
        resize_on_border = true,
        allow_tearing = false,
    },

    decoration = {
        rounding = 12,
        rounding_power = 2,
        active_opacity = 1.0,
        inactive_opacity = 1.0,
        shadow = {
            enabled = true,
            range = 24,
            render_power = 3,
            color = 0xee11111b,
        },
        blur = {
            enabled = true,
            size = 6,
            passes = 3,
            vibrancy = 0.1696,
        },
    },

    animations = {
        enabled = true,
    },

    dwindle = {
        preserve_split = true,
    },

    master = {
        new_status = "master",
    },

    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
    },

    input = {
        kb_layout = "de",
        kb_variant = "",
        kb_model = "",
        kb_options = "",
        kb_rules = "",
        follow_mouse = 1,
        sensitivity = 0,
        numlock_by_default = true,
        repeat_delay = 250,
        repeat_rate = 40,
        touchpad = {
            natural_scroll = true,
        },
    },

    cursor = {
        no_hardware_cursors = false,
    },

    xwayland = {
        force_zero_scaling = true,
    },
})

hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })

hl.animation({ leaf = "global", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "border", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "windows", enabled = true, speed = 8, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 8, bezier = "easeOutQuint", style = "popin 80%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 7, bezier = "easeInOutCubic", style = "popin 80%" })
hl.animation({ leaf = "fade", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 6, bezier = "easeOutQuint", style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 8, bezier = "easeOutQuint", style = "slidevert" })

---------------------
---- KEYBINDINGS ----
---------------------

-- Apps
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd("hyprctl reload"))

-- Session
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exec_cmd("wlogout --protocol layer-shell"))
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))
hl.bind(mainMod .. " + SHIFT + C", hl.dsp.exec_cmd("kitty --class cava -e cava"))

-- Focus
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }))

-- Move windows
hl.bind(mainMod .. " + SHIFT + left", hl.dsp.window.move({ direction = "l" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "r" }))
hl.bind(mainMod .. " + SHIFT + up", hl.dsp.window.move({ direction = "u" }))
hl.bind(mainMod .. " + SHIFT + down", hl.dsp.window.move({ direction = "d" }))

-- Resize windows
hl.bind(mainMod .. " + CTRL + left", hl.dsp.window.resize({ x = -40, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + right", hl.dsp.window.resize({ x = 40, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + up", hl.dsp.window.resize({ x = 0, y = -40, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + down", hl.dsp.window.resize({ x = 0, y = 40, relative = true }), { repeating = true })

-- Workspaces 1-10
for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = tostring(i) }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = tostring(i) }))
end

-- Mouse workspace switching and drag/resize
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Media and volume
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true, repeating = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

-- Screenshots and clipboard
hl.bind("Print", hl.dsp.exec_cmd("sh -c '~/.config/hypr/scripts/screenshot-region.sh'"))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd("sh -c '~/.config/hypr/scripts/screenshot-full.sh'"))
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.exec_cmd("sh -c '~/.config/hypr/scripts/clipboard-history.sh'"))

--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

hl.window_rule({ name = "pavucontrol", match = { class = "^(org\\.pulseaudio\\.pavucontrol|pavucontrol)$" }, float = true, center = true, size = "900 600" })
hl.window_rule({ name = "blueman", match = { class = "^(blueman-manager)$" }, float = true, center = true })
hl.window_rule({ name = "nm-connection-editor", match = { class = "^(nm-connection-editor)$" }, float = true, center = true })
hl.window_rule({ name = "cava", match = { class = "^(cava)$" }, float = true, center = true, size = "900 320" })
hl.window_rule({ name = "kitty-opacity", match = { class = "^(kitty)$" }, opacity = "0.95 0.90" })
hl.window_rule({ name = "suppress-maximize", match = { class = ".*" }, suppress_event = "maximize" })
