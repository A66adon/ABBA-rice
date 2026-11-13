# A slim Hyprland session next to KDE Plasma

This repository adds a **Hyprland session** to a machine where **KDE Plasma is
already installed and in daily use**. It does not install a theme, a rice, a
prompt, a font, or a ready-made desktop. The Hyprland starter is deliberately
minimal: auto-detected monitors, one terminal bind, one close-window bind, and
one exit bind.

The repo records the components *you* choose. On a new Arch/CachyOS machine,
`git clone` + `./install.sh` installs the base, every module recorded in
`enabled.txt`, and the matching `hosts/<hostname>/` package.

There is no website. Everything is done through `./install.sh`.

## Requirements

- Arch Linux or CachyOS (the installer refuses other distributions).
- KDE Plasma already installed; you can keep using it as the default session.
- A normal user account with `sudo` rights (sudo is used only around pacman).
- Network access for the first package install.
- `git` and `stow` (the base install includes `stow`; `git` is already present
  because you cloned the repo).
- A synced package database. Run `sudo pacman -Syu` yourself first if it is
  stale; the installer never does `-Sy` or a partial upgrade.

## Install

```bash
git clone <your-repo-url> ~/ABBA-rice
cd ~/ABBA-rice
./install.sh --dry-run     # recommended first
./install.sh
```

The plain run:

1. Refuses root and non-Arch systems.
2. Reads `base/packages.txt` (`hyprland`, `kitty`, `stow`, `jq`, `curl`).
3. Previews the package transaction (`pacman -Sp`), including new and upgraded
   packages.
4. Runs the pre-install red-flag check (`pacman -Fl`) for autostart entries,
   systemd units, D-Bus services, profile.d, environment.d, fontconfig, udev,
   modprobe, PAM, and MIME files. KDE-visible tray/autostart entries abort the
   install. If the pacman files database is missing, the installer asks to run
   `sudo pacman -Fy` (or does it automatically in non-interactive mode); this is
   a file-list sync, not a package upgrade.
5. Installs with `pacman -S --needed` (no `-Sy`, no partial upgrades).
6. Stows `base/hypr` with `stow --simulate` first and `--no-folding`. Never
   `--adopt`.
7. If `enabled.txt` exists, installs and stows every recorded module and then
   the matching `hosts/<hostname>/` package. This is the non-interactive
   new-machine path.
8. Checks autologin **read-only** and tells you to disable it yourself if the
   session picker would be skipped.
9. Runs `kde-guard` snapshots/diff and `lint-paths`.

Flags:

```bash
./install.sh --dry-run
./install.sh --yes
./install.sh --no-packages
```

`--no-packages` stows configs only; it does not install or remove packages.
`--yes` skips confirmations but still prints the package and red-flag lists.

### enabled.txt and non-interactive runs

`enabled.txt` is the list of modules you picked. When it exists, a plain
`./install.sh` is non-interactive: it prints the preview and red-flag list and
treats your recorded choices as prior approval. It still **aborts** on a
forbidden KDE-visible tray/autostart entry or a non-scoped file conflict.

If you want prompts on a fresh-machine run anyway, remove `enabled.txt` or run
`./install.sh add`.

## Switching sessions

Log out completely (locking the screen is not enough). At the greeter, open the
session menu and choose **Hyprland**. KDE Plasma remains installed and
selectable.

If autologin is enabled, the session picker never appears. The installer only
prints a notice; it **never edits** `/etc/plasmalogin.conf`, SDDM, or GDM. Disable
autologin yourself in KDE's login-manager settings.

## The slim starter

`base/hypr/.config/hypr/hyprland.lua` contains only:

| Keys | Action |
|---|---|
| `Super+Return` | Open the terminal (`kitty`) |
| `Super+Q` | Close the active window |
| `Super+M` | Exit Hyprland |

The monitor rule is the catch-all auto rule: `output=""`, preferred mode, auto
position, auto scale. There are no hardcoded monitor names, no autostart
entries, no environment variables, no theme, and no extra keybinds.

Machine-specific values are loaded from `~/.config/hypr/host.lua` when a
matching `hosts/<hostname>/` package is stowed. Without one, the auto defaults
apply.

## Adding a component

```bash
./install.sh add
```

Pick one or more modules. The installer shows the package preview, runs the
red-flag check, asks for confirmation, installs, stows the module, and records
it in `enabled.txt`.

Modules are package-only by default. Configure the app normally in your home
directory, then record the files you want:

```bash
./install.sh adopt waybar
```

`adopt` moves **only** files under that module's declared `config_paths` into
`modules/<name>/` and stows them back. It refuses paths outside those paths,
refuses symlinks outside the repo, and never uses `stow --adopt`.

Shared modules (`fish`, `starship`, `tmux`, `nvim`, `btop`, `fastfetch`, `cava`,
`git`) are also reachable from KDE. They are never in the base, carry a visible
warning in the catalog, and abort on conflict instead of backing files up.

Remove a module with:

```bash
./install.sh remove waybar
```

Unstowing and removing it from `enabled.txt` is automatic. Package removal is
offered only after asking, and uses `pacman -R` without `-s`/`-n` so
dependencies stay installed. Packages used by the base or another enabled module
are not offered for removal.

List modules and status:

```bash
./install.sh list
```

## Deploying on a new machine

On the machine where you configured everything:

```bash
./install.sh add                 # record choices in enabled.txt
./install.sh host                # optional per-machine values
git add enabled.txt modules hosts docs
git commit
```

On the new Arch/CachyOS machine:

```bash
git clone <your-repo-url> ~/ABBA-rice
cd ~/ABBA-rice
./install.sh
```

With `enabled.txt` present this installs the base, all recorded modules, and the
matching host package without prompts. If the hostname does not match any
`hosts/<hostname>/` directory, auto defaults apply.

## Per-machine values

```bash
./install.sh host
```

`scripts/host.sh` reads, but does not modify:

- `hyprctl monitors -j` — only inside a running Hyprland session; otherwise it
  skips monitor rules and says so.
- `localectl status` — keyboard layout/variant.
- `/sys/class/drm/card*/device/vendor` — GPU vendor. An NVIDIA environment block
  is written only when NVIDIA is detected and you confirm it.
- `hostnamectl chassis` or `/sys/class/power_supply/BAT*` — laptop detection.
  Laptops get a touchpad block and a Waybar battery/backlight fragment.

Output goes to the committed `hosts/<hostname>/` package. It contains only
`.config/hypr/host.lua` and, on laptops, `.config/waybar/host.jsonc`. The Waybar
fragment has no `output` key; include it from your own Waybar config if you want
it. No absolute `/home/...` paths are generated.

## What the repo guarantees about KDE

The repo **never**:

- changes your login shell or `$SHELL` (no `chsh`);
- edits `/etc`, `/usr`, login-manager config, `vconsole.conf`, environment,
  profile.d, PAM, udev, modprobe, or Bluetooth configuration;
- enables, disables, masks, or starts systemd units (system or user);
- writes environment variables outside Hyprland's own config;
- writes fontconfig files, sets a system font, or runs `fc-cache`;
- touches KDE/Plasma/Konsole/GTK/dconf/themes/cursors;
- overwrites files it did not create (`stow --adopt` is never used).

Installing packages can add files. That is why the pre-install red-flag check
exists and why KDE-visible tray/autostart entries abort the install.

### Verify with kde-guard

Take snapshots from a **TTY with no Plasma session active**; Plasma rewrites its
own files while running.

```bash
./install.sh doctor
```

`doctor` runs `scripts/lint-paths` and compares the two most recent
`kde-guard` snapshots. You can also use the guard directly:

```bash
scripts/kde-guard snapshot
scripts/kde-guard diff <before-dir> <after-dir>
```

The guard records: login shell; sha256 of readable `/etc` files; enabled system
and user units; `pacman -Qq`; autostart/systemd-user/D-Bus/wayland-session
listings; `fc-match` for monospace/sans-serif/serif/emoji; `kreadconfig6` fonts;
and hashes of KDE config globs, the Plasma panel file, Konsole profiles, shell rc
files, shared tool configs, and `~/.gitconfig`.

New package files explain their own additions. A file changed by a repo module is
reported as scoped (expected) or shared (warning). Anything else is a failure.
Fonts must remain byte-identical in `fc-match`; otherwise the guard fails.

**Do not claim KDE is untouched unless `./install.sh doctor` reports no
unexplained changes.** Shared modules can affect KDE-visible tools by design.

## Module catalog

See [`docs/CATALOG.md`](docs/CATALOG.md) for the generated package list, scope,
config paths, and warnings.

<!-- BEGIN MODULE TABLE -->
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
<!-- END MODULE TABLE -->

## Troubleshooting

**No Hyprland entry at the login screen**
```bash
ls /usr/share/wayland-sessions/
```
The `hyprland` package owns `hyprland.desktop`. If it is missing, the package is
not installed; do not create the file by hand.

**Autologin skips the greeter**
Disable autologin in KDE's login-manager settings. The installer only reads the
config and prints a notice.

**Hyprland starts but there is no bar/launcher/notifications**
Those are separate modules. Run `./install.sh add`, then start the component from
your own Hyprland config. The repo does not autostart anything.

**A module conflict aborts the install**
A scoped module may back up a conflicting regular file under
`~/.local/state/<repo>/backup/<timestamp>/`. Shared modules never do; move the
file yourself or choose a different module. The installer never overwrites a
file it did not create.

**stow is missing**
Run without `--no-packages`, or install `stow` first.

**AUR packages**
The catalog uses official packages only. If you add an `aur=` entry yourself,
the installer uses an already-installed `paru`/`yay`, previews it, and asks per
package. It never installs an AUR helper.

**Hyprland config errors**
Start Hyprland from a TTY to see errors, or inspect the Hyprland log. The starter
is intentionally small; put machine values in `hosts/<hostname>/` rather than
editing shared configs.

## Rollback

- Remove one module: `./install.sh remove <module>`.
- Unstow everything: `stow -D --dir=base --target="$HOME" hypr` and
  `./install.sh remove <module>` for each module.
- Restore a scoped conflict: copy the file back from
  `~/.local/state/<repo>/backup/<timestamp>/` using its `manifest.tsv`.
- There is **no `/etc` restore** because the repo never writes `/etc`.

The old demo is preserved on the local `archive/old-demo` branch; it is not part
of the new design.

## Notes

- Hyprland 0.55+ uses `hyprland.lua`; `hyprland.conf` is legacy.
- The base terminal is `kitty`. If you want fish only inside that terminal, put
  `shell /usr/bin/fish` in your own kitty config and adopt it; the login shell
  is never changed.
- No fonts are installed by the base. If you add a font package, it is opt-in and
  `kde-guard` must show unchanged `fc-match` output.
- The repo does not install a theme, cursor theme, prompt, or wallpaper.
