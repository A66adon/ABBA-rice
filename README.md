# dotfiles — Catppuccin Mocha demo rice

A small, complete starter setup for **CachyOS / Arch Linux** using **GNU Stow**.
It adds a **Hyprland** session next to your existing **KDE Plasma** session at the
login screen. **KDE is not modified.**

This is a working demo, not a locked-in full rice: edit the files in this repo,
rerun `stow`, and the changes are live.

## Stack

| Layer | Choice |
|---|---|
| Session | Hyprland (KDE Plasma remains the default and is untouched) |
| Login | Plasma Login Manager session picker (autologin disabled) |
| Terminal | Kitty |
| Shell | fish + Starship |
| Theme | Catppuccin Mocha |
| Font | JetBrainsMono Nerd Font |
| Bar | Waybar (all three monitors) |
| Launcher | Wofi |
| Notifications | Mako |
| Wallpaper | Hyprpaper (generated Catppuccin wallpaper) |
| Lock / idle | Hyprlock + Hypridle |
| Power menu | wlogout |
| Multiplexer | tmux |
| Editor | Neovim + LazyVim |
| Extras | btop, fastfetch, cava, eza, bat, fd, rg, fzf, zoxide |

## Repository layout

```text
~/dotfiles/
├── install.sh                  # one-command installer
├── README.md
├── packages/
│   ├── pacman.txt              # official repo packages
│   └── aur.txt                 # optional AUR packages
├── scripts/
│   ├── lib.sh                  # shared helpers
│   ├── make-wallpaper.sh       # regenerate the wallpaper
│   ├── restore.sh              # restore an install backup
│   └── verify.sh               # check symlinks and commands
├── hypr/.config/hypr/          # Hyprland, Hyprpaper, Hyprlock, Hypridle, scripts
├── waybar/.config/waybar/      # bar config + Catppuccin CSS
├── wofi/.config/wofi/          # launcher
├── mako/.config/mako/          # notifications
├── wlogout/.config/wlogout/    # power menu
├── kitty/.config/kitty/        # terminal
├── fish/.config/fish/          # shell config
├── starship/.config/           # prompt
├── tmux/.config/tmux/          # multiplexer
├── btop/.config/btop/          # monitor + theme
├── fastfetch/.config/fastfetch/
├── cava/.config/cava/
├── nvim/.config/nvim/          # LazyVim + Catppuccin
└── git/.gitconfig
```

Every top-level directory is a Stow package. The only thing the installer needs
from you is your sudo password (and your password at the login screen after
autologin is disabled).

## Install

```bash
git clone <your-repo-url> ~/dotfiles
cd ~/dotfiles
./install.sh --dry-run     # recommended first
./install.sh
```

Already on this machine? The repo is at `~/dotfiles`:

```bash
cd ~/dotfiles
./install.sh
```

The installer asks for your sudo password once for the package installation
and the login-manager change.

The installer:

1. Verifies CachyOS/Arch and that you are not running as root.
2. Installs the packages in `packages/pacman.txt` (and AUR packages if
   `paru`/`yay` is available).
3. Backs up conflicting files to `~/.dotfiles-backup/<timestamp>/`.
4. Stows all packages with `--no-folding --restow`.
5. Refreshes fonts and generates the wallpaper if missing.
6. Pre-installs Neovim plugins (network required).
7. Disables Plasma Login Manager autologin so the session picker appears.
8. Ensures the Hyprland Wayland session entry exists.
9. Sets fish as the login shell if needed.
10. Runs `scripts/verify.sh`.

Useful flags:

```bash
./install.sh --dry-run
./install.sh --no-packages
./install.sh --no-autologin
./install.sh --no-warmup
./install.sh --no-verify
./install.sh --only fish,kitty,starship
./install.sh --restore <timestamp>
```

## Switching between KDE and Hyprland

Switching is more than `Win+L` (that only locks the screen). It requires a
logout, because KDE and Hyprland are separate graphical sessions:

1. After the first install, reboot once so Plasma Login Manager re-reads its
   config (it caches the file until the service restarts).
2. At the Plasma Login Manager greeter, open the session menu in the
   **bottom-left** and pick **Hyprland**.
3. Log in. To go back, log out of Hyprland and pick **Plasma**.

KDE Plasma is still the preselected/default session. Your KDE config, theme,
panel, wallpaper, and shortcuts were not touched.

## Key binds (Hyprland)

| Keys | Action |
|---|---|
| `Super+Return` | Kitty |
| `Super+D` | Wofi launcher |
| `Super+E` | Dolphin |
| `Super+Q` | Close window |
| `Super+F` | Fullscreen |
| `Super+V` | Toggle floating |
| `Super+1..9,0` | Workspace 1–10 |
| `Super+Shift+1..9,0` | Move window to workspace |
| `Super+L` | Lock (Hyprlock) |
| `Super+Shift+V` | Clipboard history |
| `Print` | Region screenshot to clipboard + file |
| `Shift+Print` | Full screenshot to clipboard + file |
| `Super+Shift+E` | Power menu (wlogout) |
| `Super+Shift+C` | cava in a floating kitty |
| `Super+S` | Toggle scratchpad |
| `Super+Shift+S` | Move window to scratchpad |
| `Super+Arrows` | Focus window |
| `Super+Shift+Arrows` | Move window |
| `Super+Ctrl+Arrows` | Resize window |
| `Super+Mouse wheel` | Switch workspaces |

Media/volume keys are bound through `wpctl` and `playerctl`.

## Customization

### Change a config

Edit the file in this repo, then restow the package:

```bash
cd ~/dotfiles
stow -R -t ~ hypr
```

Hyprland reloads its config automatically when it changes. For Waybar:

```bash
killall waybar; waybar &
```

### Colors

Catppuccin Mocha values are repeated in the individual configs by design
(no generated theme engine):

- `kitty/.config/kitty/kitty.conf`
- `fish/.config/fish/config.fish` (`FZF_DEFAULT_OPTS`, bat theme)
- `starship/.config/starship.toml`
- `tmux/.config/tmux/tmux.conf`
- `waybar/.config/waybar/style.css`
- `hypr/.config/hypr/hyprland.lua`
- `wofi/.config/wofi/style.css`
- `mako/.config/mako/config`
- `wlogout/.config/wlogout/style.css`

### Monitors

Hyprland 0.57+ uses the Lua configuration format. The monitor layout is in
`hypr/.config/hypr/hyprland.lua`:

```lua
hl.monitor({ output = "DP-1", mode = "2560x1440@164.96", position = "4480x0", scale = 1 })
hl.monitor({ output = "HDMI-A-2", mode = "2560x1440@59.95", position = "1920x0", scale = 1 })
hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@60.00", position = "0x188", scale = 1 })
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })
```

Delete the three explicit lines to let Hyprland auto-detect, or edit the names
with `hyprctl monitors`.

Waybar targets the same three outputs in
`waybar/.config/waybar/config.jsonc`:

```json
"output": ["DP-1", "HDMI-A-2", "HDMI-A-1"]
```

### Wallpaper

```bash
./scripts/make-wallpaper.sh
```

The PNG is committed at `hypr/.config/hypr/wallpapers/catppuccin-mocha.png`.

### Packages

Add packages to `packages/pacman.txt` or `packages/aur.txt`, then rerun:

```bash
./install.sh --no-autologin --no-warmup
```

### Add a new Stow package

```bash
mkdir -p ~/dotfiles/myapp/.config/myapp
# put files under ~/dotfiles/myapp/.config/myapp/
cd ~/dotfiles
stow -t ~ myapp
```

Add `myapp` to the `PACKAGES` array in `install.sh` and `scripts/restore.sh`
if you want it handled by the installer.

## Rollback

Every conflicting file is moved to `~/.dotfiles-backup/<timestamp>/` and listed
in `manifest.tsv`. To undo an install:

```bash
cd ~/dotfiles
./install.sh --restore <timestamp>
```

Then log out and back in. The original `/etc/plasmalogin.conf` is restored too.

## Push to GitHub

The repository is initialized locally; no remote is configured.

```bash
cd ~/dotfiles
git remote add origin git@github.com:<your-user>/dotfiles.git
git push -u origin main
```

If you prefer HTTPS:

```bash
git remote add origin https://github.com/<your-user>/dotfiles.git
git push -u origin main
```

Before pushing, check that `git/.gitconfig` contains the name/email you want to
publish. No SSH keys, tokens, or wallet files are stored in this repo.

After the first Neovim launch, `nvim/.config/nvim/lazy-lock.json` will change.
Commit it to keep plugin versions reproducible:

```bash
git add nvim/.config/nvim/lazy-lock.json
git commit -m "chore: update lazy-lock"
```

## Troubleshooting

**No Hyprland entry at login**
```bash
ls /usr/share/wayland-sessions/
```
If `hyprland.desktop` is missing, make sure the `hyprland` package is
installed, then rerun `./install.sh --no-packages`.

**Autologin still skips the greeter**
```bash
grep -A3 '\[Autologin\]' /etc/plasmalogin.conf
```
`User=` should be absent. `Session=plasma.desktop` is kept so KDE remains the
default choice. Reboot after the change; Plasma Login Manager caches its config.

**Hyprland starts but there is no bar**
```bash
waybar
```
Check the error output. The config is `~/.config/waybar/config.jsonc`; validate
JSON with:
```bash
jq . ~/.config/waybar/config.jsonc
```

**No wallpaper**
```bash
hyprpaper
```
Check that `~/.config/hypr/wallpapers/catppuccin-mocha.png` exists and that the
path in `hyprpaper.conf` is correct.

**Hyprland fails to start**
Log back into KDE (it is untouched), then inspect:
```bash
cat ~/.local/share/hyprland/hyprland.log
```
or start it from a TTY with `Hyprland` to see the error.

**Kitty/fish prompt looks wrong**
```bash
fish -n ~/.config/fish/config.fish   # syntax check
starship --version
```
Make sure `JetBrainsMono Nerd Font` is installed:
```bash
fc-list | grep -i "JetBrainsMono Nerd Font"
```

**Neovim plugins did not install**
Open `nvim` and run `:Lazy sync`. The first run needs network access.

## Notes

- Hyprland 0.57+ uses `hyprland.lua`; legacy `hyprland.conf` is no longer loaded.
- Hyprland is a separate session; KDE applications are not migrated.
- The Hyprland monitor layout is tuned to the machine it was built on.
- `bibata-cursor-theme-bin` is optional. Without an AUR helper the installer
  skips it and Hyprland falls back to the default cursor.
- `install.sh` intentionally refuses to run on non-Arch distributions.
