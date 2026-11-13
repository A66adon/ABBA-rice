# Module catalog

Generated from `modules/*/module.conf` by `scripts/gen-catalog`. Do not edit by hand.

Scoped modules run only inside Hyprland. Shared modules are reachable from KDE too; they are never in the base, conflicts abort, and their configs may change KDE-visible tooling. Each module is package-only by default; configure the app normally in `$HOME`, then run `./install.sh adopt <module>`.

| Module | Scope | Category | Packages | Description | Warning |
|---|---|---|---|---|---|
| `btop` | shared | Monitor | btop | btop configuration (shared). | **Shared: may affect KDE** |
| `cava` | shared | Visualizer | cava | cava audio visualizer configuration (shared). | **Shared: may affect KDE** |
| `fastfetch` | shared | Fetch | fastfetch | fastfetch configuration (shared). | **Shared: may affect KDE** |
| `fish` | shared | Shell | fish | Fish shell configuration (shared with KDE terminals). | **Shared: may affect KDE** |
| `git` | shared | VCS | git | Git package metadata; the repo never ships ~/.gitconfig. | **Shared: may affect KDE** |
| `hypridle` | scoped | Idle | hypridle | Idle/lock daemon for the Hyprland session. |  |
| `hyprlock` | scoped | Lock | hyprlock | Screen locker for the Hyprland session. |  |
| `hyprpaper` | scoped | Wallpaper | hyprpaper | Wallpaper daemon for the Hyprland session. |  |
| `kitty` | scoped | Terminal | kitty | Terminal used by the starter (base install already provides it). |  |
| `mako` | scoped | Notifications | mako | Notification daemon for the Hyprland session. |  |
| `nvim` | shared | Editor | neovim | Neovim configuration (shared). | **Shared: may affect KDE** |
| `starship` | shared | Prompt | starship | Starship prompt configuration (shared). | **Shared: may affect KDE** |
| `tmux` | shared | Multiplexer | tmux | tmux configuration (shared). | **Shared: may affect KDE** |
| `waybar` | scoped | Bar | waybar | Status bar for the Hyprland session. |  |
| `wlogout` | scoped | Power menu | wlogout | Power menu for the Hyprland session. |  |
| `wofi` | scoped | Launcher | wofi | Application launcher for the Hyprland session. |  |

## Module notes

### `btop`

- Scope: `shared`
- Category: Monitor
- Packages: `btop`
- Config paths: `.config/btop`
- Notes: Shared scope: reachable from KDE too. Conflicts abort and changes may be visible in KDE; configure it normally, then adopt.

### `cava`

- Scope: `shared`
- Category: Visualizer
- Packages: `cava`
- Config paths: `.config/cava`
- Notes: Shared scope: reachable from KDE too. Conflicts abort and changes may be visible in KDE; configure it normally, then adopt.

### `fastfetch`

- Scope: `shared`
- Category: Fetch
- Packages: `fastfetch`
- Config paths: `.config/fastfetch`
- Notes: Shared scope: reachable from KDE too. Conflicts abort and changes may be visible in KDE; configure it normally, then adopt.

### `fish`

- Scope: `shared`
- Category: Shell
- Packages: `fish`
- Config paths: `.config/fish`
- Notes: Shared scope: reachable from KDE too. Conflicts abort and changes may be visible in KDE; configure it normally, then adopt.

### `git`

- Scope: `shared`
- Category: VCS
- Packages: `git`
- Config paths: ``
- Notes: Shared scope; package only. ~/.gitconfig is on the stow denylist and is never shipped or adopted.

### `hypridle`

- Scope: `scoped`
- Category: Idle
- Packages: `hypridle`
- Config paths: `.config/hypr/hypridle.conf`
- Notes: Scoped to Hyprland; the repo does not enable systemd units or autostart it. Configure normally, then run ./install.sh adopt hypridle.

### `hyprlock`

- Scope: `scoped`
- Category: Lock
- Packages: `hyprlock`
- Config paths: `.config/hypr/hyprlock.conf`
- Notes: Scoped to Hyprland; the repo does not autostart it. Configure normally, then run ./install.sh adopt hyprlock.

### `hyprpaper`

- Scope: `scoped`
- Category: Wallpaper
- Packages: `hyprpaper`
- Config paths: `.config/hypr/hyprpaper.conf`
- Notes: Scoped to Hyprland; the repo does not autostart it. Configure normally, then run ./install.sh adopt hyprpaper.

### `kitty`

- Scope: `scoped`
- Category: Terminal
- Packages: `kitty`
- Config paths: `.config/kitty`
- Notes: Scoped to Hyprland. Base already installs kitty; this module records terminal config only. It never changes the login shell.

### `mako`

- Scope: `scoped`
- Category: Notifications
- Packages: `mako`
- Config paths: `.config/mako`
- Notes: Scoped to Hyprland. The package ships a user service and a D-Bus notification service; do not enable it, start it from your Hyprland config instead.

### `nvim`

- Scope: `shared`
- Category: Editor
- Packages: `neovim`
- Config paths: `.config/nvim`
- Notes: Shared scope: reachable from KDE too. The repo ships no plugin manager and runs no warm-up; configure it normally, then adopt.

### `starship`

- Scope: `shared`
- Category: Prompt
- Packages: `starship`
- Config paths: `.config/starship.toml`
- Notes: Shared scope: reachable from KDE too. Conflicts abort and changes may be visible in KDE; configure it normally, then adopt.

### `tmux`

- Scope: `shared`
- Category: Multiplexer
- Packages: `tmux`
- Config paths: `.config/tmux`
- Notes: Shared scope: reachable from KDE too. Conflicts abort and changes may be visible in KDE; configure it normally, then adopt.

### `waybar`

- Scope: `scoped`
- Category: Bar
- Packages: `waybar`
- Config paths: `.config/waybar`
- Notes: Scoped to Hyprland. No output key is shipped, so Waybar appears on all monitors; edit your own config after ./install.sh add waybar.

### `wlogout`

- Scope: `scoped`
- Category: Power menu
- Packages: `wlogout`
- Config paths: `.config/wlogout`
- Notes: Scoped to Hyprland; the repo does not autostart it. A minimal layout is shipped because wlogout needs one; edit it and adopt your changes.

### `wofi`

- Scope: `scoped`
- Category: Launcher
- Packages: `wofi`
- Config paths: `.config/wofi`
- Notes: Scoped to Hyprland; the repo does not autostart it. Configure normally, then run ./install.sh adopt wofi.

