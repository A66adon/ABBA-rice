# Hyprland bootstrap for Arch Linux

## What this is

Adds Hyprland next to an existing KDE Plasma install on Arch Linux. It installs packages and links the configs in `stow/` into your home folder. It does not edit your KDE configs.

## What you need

- Arch Linux (the installer checks for `/etc/arch-release`)
- KDE Plasma already installed and working
- `git` (run `sudo pacman -S git` if it is missing)
- Internet access and a user account with `sudo`

## What the files do

| File | What it does |
| --- | --- |
| `install.sh` | Installs every package in `packages.txt`. |
| `deploy.sh` | Links the configs in `stow/` into `~/.config`. |
| `packages.txt` | The package list used by `install.sh`. |
| `stow/` | One folder per app, holding that app's config. |

## Install

1. **Update Arch.**

   ```bash
   sudo pacman -Syu
   ```

   Updates everything. Do this before installing new packages.

2. **Download the repo.**

   ```bash
   git clone https://github.com/A66adon/ABBA-rice.git
   ```

   Copies the repo into your home folder.

3. **Enter the repo folder.**

   ```bash
   cd ABBA-rice
   ```

   Run all later commands from here.

4. **Install the packages.**

   ```bash
   ./install.sh
   ```

   Installs everything in `packages.txt`. Asks for your password. Safe to re-run.

5. **Answer pacman.** Press `y` to continue. Press `n` if you see unexpected fonts, themes, KDE packages, or autostart packages, then check why.

6. **Link the configs.**

   ```bash
   ./deploy.sh
   ```

   Symlinks the configs into `~/.config`. Run this before the first Hyprland start.

7. **Log out and select Hyprland** in the login screen's session menu.

## First start

The starter config is at `~/.config/hypr/hyprland.lua`. It is a symlink into `stow/hypr/`, so edits are saved in the repo too.

Default keys (`SUPER` is the Windows key):

| Keys | Action |
| --- | --- |
| `SUPER + Q` | Open kitty |
| `SUPER + C` | Close the focused window |
| `SUPER + R` | Open the launcher (needs `hyprlauncher`) |
| `SUPER + E` | Open Dolphin |
| `SUPER + M` | Exit Hyprland |

No bar at the top is normal: Waybar is not installed by default.

If something goes wrong, log out and pick Plasma again.

## Add a package

Waybar as the example. Replace `waybar` with your package name.

1. **Install it.**

   ```bash
   sudo pacman -S waybar
   ```

   Installs waybar and its dependencies now.

2. **Add it to `packages.txt`.**

   ```bash
   echo waybar >> packages.txt
   ```

   Makes `install.sh` install it on new machines.

3. **Run the package check.**

   ```bash
   pacman -Si waybar
   ```

   Shows version, size, dependencies, and description.

   ```bash
   pacman -Ql waybar | grep -E '/etc/xdg/autostart|dbus-1/services|systemd/user|profile\.d|/etc/environment|fontconfig|/usr/share/fonts'
   ```

   Lists files that start on login or change system-wide settings. No output means nothing risky.

   Not installed yet? Run `sudo pacman -Fy` once, then `pacman -Fl waybar`.

   Something risky? Remove it with `sudo pacman -Rs waybar` and delete its line from `packages.txt`.

4. **Configure it** in `~/.config/waybar` (create the folder if needed).

5. **Move the config into the repo.**

   ```bash
   mkdir -p stow/waybar/.config
   mv ~/.config/waybar stow/waybar/.config/waybar
   ./deploy.sh
   ```

   - `mkdir -p` creates the matching folder under `stow/`.
   - `mv` moves the real config into the repo.
   - `deploy.sh` links it back to `~/.config/waybar`.

6. **Save the change.**

   ```bash
   git add .
   git commit -m "Add waybar"
   ```

   Stages and commits the new package.

## Pick extra components (optional)

These are examples, not recommendations. None are needed for the first start.

- Terminal: kitty, foot, alacritty
- Bar: waybar
- Launcher: wofi, fuzzel
- Notifications: mako, dunst
- Wallpaper: hyprpaper, swaybg

See the "Useful Utilities" page: <https://wiki.hypr.land/useful-utilities/>

## New machine

After a fresh Arch + KDE install (`sudo pacman -S git` first if needed):

```bash
sudo pacman -Syu
git clone https://github.com/A66adon/ABBA-rice.git
cd ABBA-rice
./install.sh
./deploy.sh
```

Then log out and pick Hyprland. Run `deploy.sh` before the first Hyprland start.

## KDE safety

- Only customize apps that are not part of KDE.
- Do not change settings of shared apps (Dolphin, Konsole, System Settings) while in Hyprland: KDE uses the same config.
- Fonts and shell prompt changes leak into KDE.
- Never use `stow --adopt`.

## Troubleshooting

- `Do not run as root.` → Run `./install.sh` as your normal user, without `sudo`.
- `This is not Arch Linux.` → The script only supports Arch (it checks `/etc/arch-release`).
- `A real file is in the way.` → Something already exists where a link should go. Move it away, then run `./deploy.sh` again.
- No Hyprland at the login screen → Finish the install, log out fully (or reboot), and check the session menu again.

## AUR packages

None. If you install an AUR package by hand, list it here so you remember.
