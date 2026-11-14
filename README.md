# Hyprland bootstrap for Arch Linux

## What this is

A minimal Arch Linux bootstrap that adds Hyprland next to an existing KDE Plasma install.
It installs packages only and does not configure Hyprland or touch KDE.

## Install

1. Run `sudo pacman -Syu` yourself first.
2. `git clone <your-repo-url>`
3. `cd <repo>`
4. `./install.sh`
5. Read the package list pacman shows and answer "n" if it contains fonts, themes, KDE packages or autostart-type packages.
6. Log out and choose "Hyprland" in the login screen's session selector.

## First start

Hyprland generates its own default config on first launch. Open that file and read the default key binds there (terminal, close window, exit); they change between versions.

On a new machine, run `./deploy.sh` BEFORE the first Hyprland start.

## Pick components

These are examples, not recommendations.

- Terminal: kitty, foot, alacritty
- Bar: waybar
- Launcher: wofi, fuzzel
- Notifications: mako, dunst
- Wallpaper: hyprpaper, swaybg

See the "Useful Utilities" section at https://wiki.hypr.land/useful-utilities/.

## Add a component

Waybar as the example:

1. Install it with pacman.
2. Add its name to `packages.txt`.
3. Run the PACKAGE CHECK: `pacman -Si <pkg>`, then `pacman -Ql <pkg> | grep -E '/etc/xdg/autostart|dbus-1/services|systemd/user|profile\.d|/etc/environment|fontconfig|/usr/share/fonts'`. For an uninstalled package use `pacman -Fl <pkg>` after `sudo pacman -Fy`.
4. Configure it in `~/.config/waybar` as normal.
5. Run `mkdir -p stow/waybar/.config && mv ~/.config/waybar stow/waybar/.config/waybar && ./deploy.sh`.
6. `git commit`.

## New machine

`git clone <your-repo-url>`, `cd <repo>`, `./install.sh`, `./deploy.sh`, then pick the Hyprland session.

## KDE safety

- Only rice Hyprland-only apps.
- Do not change settings of shared apps (Dolphin, Konsole, System Settings) while in Hyprland because they share config with KDE.
- Fonts and shell prompt changes leak into KDE.
- Never use `stow --adopt`.

## AUR packages

None. Install any by hand and list them here.
