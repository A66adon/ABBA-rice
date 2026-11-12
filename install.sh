#!/usr/bin/env bash
# One-command installer for the dotfiles repository.
#
# Usage:
#   ./install.sh [--dry-run] [--yes] [--no-packages] [--no-autologin]
#                [--no-warmup] [--only pkg1,pkg2] [--restore <timestamp>]
set -Eeuo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib.sh
source "$REPO_DIR/scripts/lib.sh"

PACKAGES=(hypr waybar wofi mako wlogout kitty fish starship tmux btop fastfetch cava nvim git)
DRY_RUN=0
ASSUME_YES=0
DO_PACKAGES=1
DO_AUTOLOGIN=1
DO_WARMUP=1
DO_VERIFY=1
ONLY=""
RESTORE_TS=""

usage() {
  cat <<'EOF'
Usage: ./install.sh [options]

  --dry-run          Show what would happen; change nothing.
  -y, --yes          Assume yes for confirmations.
  --no-packages      Do not install pacman/AUR packages.
  --no-autologin     Do not touch Plasma Login Manager autologin.
  --no-warmup        Do not pre-install Neovim plugins.
  --no-verify        Skip the post-install verification step.
  --only LIST        Only stow these comma-separated packages.
  --restore TS       Restore a backup from ~/.dotfiles-backup/TS.
  -h, --help         Show this help.

Targets CachyOS / Arch Linux only.
EOF
}

while (($#)); do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    -y|--yes) ASSUME_YES=1 ;;
    --no-packages) DO_PACKAGES=0 ;;
    --no-autologin) DO_AUTOLOGIN=0 ;;
    --no-warmup) DO_WARMUP=0 ;;
    --no-verify) DO_VERIFY=0 ;;
    --only) ONLY="${2:-}"; shift ;;
    --restore) RESTORE_TS="${2:-}"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "Unknown option: $1 (try --help)" ;;
  esac
  shift
done

if [[ -n "$RESTORE_TS" ]]; then
  exec "$REPO_DIR/scripts/restore.sh" "$RESTORE_TS"
fi

[[ "$EUID" -ne 0 ]] || die "Run as your normal user, not root."
is_arch || die "This installer targets CachyOS/Arch Linux only."
have pacman || die "pacman not found."

if [[ -n "$ONLY" ]]; then
  IFS=',' read -r -a PACKAGES <<< "$ONLY"
  for pkg in "${PACKAGES[@]}"; do
    [[ -d "$REPO_DIR/$pkg" ]] || die "Unknown package: $pkg"
  done
  DO_VERIFY=0
fi

if (( DO_PACKAGES )); then
  keep_sudo_alive
fi

BACKUP_TS="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$HOME/.dotfiles-backup/$BACKUP_TS"

info "Repository: $REPO_DIR"
info "Backup:     $BACKUP_DIR"
(( DRY_RUN )) && warn "DRY RUN: no changes will be made."

# ---------------------------------------------------------------- packages
if (( DO_PACKAGES )); then
  info "Installing pacman packages..."
  mapfile -t PKGS < <(grep -vE '^[[:space:]]*(#|$)' "$REPO_DIR/packages/pacman.txt")
  if ((${#PKGS[@]})); then
    run_sudo pacman -S --needed --noconfirm "${PKGS[@]}"
  fi

  if [[ -s "$REPO_DIR/packages/aur.txt" ]]; then
    AUR=""
    if have paru; then
      AUR=paru
    elif have yay; then
      AUR=yay
    fi
    if [[ -n "$AUR" ]]; then
      mapfile -t AURPKGS < <(grep -vE '^[[:space:]]*(#|$)' "$REPO_DIR/packages/aur.txt")
      if ((${#AURPKGS[@]})); then
        info "Installing AUR packages with $AUR..."
        if (( DRY_RUN )); then
          printf '  [dry-run] %s -S --needed --noconfirm' "$AUR"
          printf ' %q' "${AURPKGS[@]}"
          printf '\n'
        else
          "$AUR" -S --needed --noconfirm "${AURPKGS[@]}"
        fi
      fi
    else
      warn "No AUR helper (paru/yay) found; skipping packages/aur.txt."
      warn "The demo still works with the default cursor."
    fi
  fi
else
  info "Skipping package installation (--no-packages)."
fi

# ---------------------------------------------------------------- backup
info "Checking for conflicting files..."
if (( ! DRY_RUN )); then
  mkdir -p "$BACKUP_DIR"
  : > "$BACKUP_DIR/manifest.tsv"
fi

backup_one() {
  local target="$1"
  [[ -e "$target" || -L "$target" ]] || return 0

  if [[ -L "$target" ]]; then
    local resolved
    resolved="$(readlink -f "$target" || true)"
    case "$resolved" in
      "$REPO_DIR"/*) return 0 ;;
    esac
  fi

  if [[ -d "$target" && ! -L "$target" ]]; then
    die "Refusing to move directory '$target' (package path collision)."
  fi

  local rel="${target#"$HOME"/}"
  local dest="$BACKUP_DIR/$rel"
  if (( DRY_RUN )); then
    info "  would back up $target"
    return 0
  fi
  mkdir -p "$(dirname "$dest")"
  mv "$target" "$dest"
  printf '%s\t%s\n' "$target" "$dest" >> "$BACKUP_DIR/manifest.tsv"
  info "  backed up ${target#"$HOME"/}"
}

while IFS= read -r target; do
  backup_one "$target"
done < <(repo_targets "${PACKAGES[@]}")

if (( ! DRY_RUN )) && [[ -s "$BACKUP_DIR/manifest.tsv" ]]; then
  sort -u -o "$BACKUP_DIR/manifest.tsv" "$BACKUP_DIR/manifest.tsv"
fi

# ---------------------------------------------------------------- stow
info "Stowing packages: ${PACKAGES[*]}"
if (( ! DRY_RUN )) && ! have stow; then
  die "stow is not installed; run without --no-packages or install stow."
fi
if (( DRY_RUN )); then
  printf '  [dry-run] stow --dir=%q --target=%q --no-folding --restow' "$REPO_DIR" "$HOME"
  printf ' %q' "${PACKAGES[@]}"
  printf '\n'
else
  stow --dir="$REPO_DIR" --target="$HOME" --no-folding --restow --verbose=1 "${PACKAGES[@]}"
fi

# ---------------------------------------------------------------- fonts / wallpaper
if have fc-cache; then
  run fc-cache -f >/dev/null
fi

if [[ ! -f "$REPO_DIR/hypr/.config/hypr/wallpapers/catppuccin-mocha.png" ]]; then
  info "Generating Catppuccin wallpaper..."
  run "$REPO_DIR/scripts/make-wallpaper.sh"
fi

# ---------------------------------------------------------------- neovim warm-up
if (( DO_WARMUP )) && have nvim; then
  info "Warming up Neovim plugins (network required on first run)..."
  if (( DRY_RUN )); then
    echo "  [dry-run] nvim --headless '+Lazy! sync' +qa"
  else
    timeout 300 nvim --headless "+Lazy! sync" +qa || \
      warn "Neovim plugin sync failed; open nvim and run :Lazy sync."
  fi
fi

# ---------------------------------------------------------------- login manager
if (( DO_AUTOLOGIN )); then
  if [[ -f /etc/plasmalogin.conf ]]; then
    if grep -qE '^\[Autologin\]' /etc/plasmalogin.conf && \
       grep -qE '^User=' /etc/plasmalogin.conf; then
      info "Disabling Plasma Login Manager autologin (backup kept)..."
      if (( DRY_RUN )); then
        echo "  [dry-run] remove User= (keep Session=plasma.desktop) under [Autologin] in /etc/plasmalogin.conf"
      else
        mkdir -p "$BACKUP_DIR/etc"
        sudo cp -a /etc/plasmalogin.conf "$BACKUP_DIR/etc/plasmalogin.conf"
        printf '%s\t%s\n' "/etc/plasmalogin.conf" "$BACKUP_DIR/etc/plasmalogin.conf" \
          >> "$BACKUP_DIR/manifest.tsv"
        tmp="$(mktemp)"
        awk '
          /^\[Autologin\]/ { in_auto = 1; print; next }
          /^\[/           { in_auto = 0 }
          in_auto && /^User=/ { next }
          { print }
        ' /etc/plasmalogin.conf > "$tmp"
        sudo install -m 644 "$tmp" /etc/plasmalogin.conf
        rm -f "$tmp"
      fi
    else
      info "Plasma Login Manager autologin is already disabled."
    fi
  else
    info "No /etc/plasmalogin.conf found; leaving display manager config alone."
  fi
fi

if [[ ! -f /usr/share/wayland-sessions/hyprland.desktop ]]; then
  if ! have Hyprland && ! have start-hyprland; then
    warn "Hyprland is not installed; skipping the Wayland session entry."
  else
    HYPR_EXEC="Hyprland"
    if have start-hyprland; then
      HYPR_EXEC="start-hyprland"
    fi
    info "Creating Hyprland Wayland session entry..."
    if (( DRY_RUN )); then
      echo "  [dry-run] create /usr/share/wayland-sessions/hyprland.desktop (Exec=$HYPR_EXEC)"
    else
      sudo tee /usr/share/wayland-sessions/hyprland.desktop >/dev/null <<EOF
[Desktop Entry]
Name=Hyprland
Comment=An intelligent dynamic tiling Wayland compositor
Exec=$HYPR_EXEC
Type=Application
DesktopNames=Hyprland
EOF
    fi
  fi
fi

# ---------------------------------------------------------------- shell
CURRENT_SHELL="$(getent passwd "$USER" | cut -d: -f7)"
if [[ "$(basename "$CURRENT_SHELL")" != "fish" ]]; then
  info "Setting login shell to fish..."
  run_sudo chsh -s /usr/bin/fish "$USER"
fi

# ---------------------------------------------------------------- verify
if (( DO_VERIFY )); then
  info "Verifying installation..."
  if (( DRY_RUN )); then
    echo "  [dry-run] scripts/verify.sh"
  else
    "$REPO_DIR/scripts/verify.sh" || warn "Verification reported issues; see above."
  fi
fi

cat <<EOF

Done.

Next steps:
  1. Reboot (recommended) or log out. Plasma Login Manager caches its config,
     so a reboot guarantees the new autologin setting is read.
  2. At the Plasma Login Manager greeter, open the session menu (bottom-left)
     and choose "Hyprland".
  3. KDE Plasma remains untouched and selectable.

Backup:   $BACKUP_DIR
Restore:  $REPO_DIR/install.sh --restore $BACKUP_TS

Key binds: Super+Return terminal, Super+D launcher, Super+E Dolphin,
Super+1..9 workspaces, Super+L lock, Print screenshot,
Super+Shift+V clipboard history, Super+Shift+E power menu.
EOF
