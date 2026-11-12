#!/usr/bin/env bash
# Restore a previous install backup created by install.sh.
set -Eeuo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib.sh
source "$REPO_DIR/scripts/lib.sh"

PACKAGES=(hypr waybar wofi mako wlogout kitty fish starship tmux btop fastfetch cava nvim git)

TS="${1:-}"
[[ -n "$TS" ]] || die "Usage: $0 <timestamp>   (see ~/.dotfiles-backup/)"
BACKUP_DIR="$HOME/.dotfiles-backup/$TS"
[[ -d "$BACKUP_DIR" ]] || die "Backup not found: $BACKUP_DIR"

if have sudo && [[ -f "$BACKUP_DIR/etc/plasmalogin.conf" ]]; then
  keep_sudo_alive
fi

info "Removing stowed symlinks..."
if have stow; then
  for pkg in "${PACKAGES[@]}"; do
    stow --dir="$REPO_DIR" --target="$HOME" --no-folding -D "$pkg" 2>/dev/null || true
  done
fi

if [[ -f "$BACKUP_DIR/manifest.tsv" ]]; then
  info "Restoring backed-up files..."
  while IFS=$'\t' read -r target backup; do
    [[ -n "$target" && -n "$backup" ]] || continue
    [[ -e "$backup" || -L "$backup" ]] || { warn "missing backup file: $backup"; continue; }
    if [[ "$target" == /etc/* ]]; then
      run_sudo mkdir -p "$(dirname "$target")"
      run_sudo cp -a "$backup" "$target"
    else
      mkdir -p "$(dirname "$target")"
      rm -f "$target"
      cp -a "$backup" "$target"
    fi
    info "restored $target"
  done < "$BACKUP_DIR/manifest.tsv"
else
  warn "No manifest.tsv in $BACKUP_DIR; only symlinks were removed."
fi

info "Restore complete. Log out and back in to pick up the previous session state."
