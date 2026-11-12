#!/usr/bin/env bash
# Verify that the dotfiles are stowed and all expected commands exist.
set -Eeuo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib.sh
source "$REPO_DIR/scripts/lib.sh"

FAIL=0

check_link() {
  local target="$1"
  if [[ -L "$target" ]]; then
    local resolved
    resolved="$(readlink -f "$target" || true)"
    case "$resolved" in
      "$REPO_DIR"/*)
        info "stowed: ${target#"$HOME"/}"
        ;;
      *)
        warn "wrong symlink target: $target -> $resolved"
        FAIL=1
        ;;
    esac
  else
    warn "not a stowed symlink: $target"
    FAIL=1
  fi
}

check_cmd() {
  if have "$1"; then
    info "command: $1"
  else
    warn "missing command: $1"
    FAIL=1
  fi
}

for cmd in kitty starship tmux nvim btop fastfetch cava waybar wofi mako \
           hyprctl hyprpaper hyprlock hypridle cliphist wl-copy grim slurp \
           wlogout eza bat fd rg fzf zoxide; do
  check_cmd "$cmd"
done

if have Hyprland || have start-hyprland; then
  info "command: Hyprland"
else
  warn "missing command: Hyprland (or start-hyprland)"
  FAIL=1
fi

for target in \
  "$HOME/.config/hypr/hyprland.lua" \
  "$HOME/.config/hypr/hyprpaper.conf" \
  "$HOME/.config/hypr/hyprlock.conf" \
  "$HOME/.config/hypr/hypridle.conf" \
  "$HOME/.config/waybar/config.jsonc" \
  "$HOME/.config/waybar/style.css" \
  "$HOME/.config/wofi/config" \
  "$HOME/.config/wofi/style.css" \
  "$HOME/.config/mako/config" \
  "$HOME/.config/wlogout/layout" \
  "$HOME/.config/wlogout/style.css" \
  "$HOME/.config/kitty/kitty.conf" \
  "$HOME/.config/fish/config.fish" \
  "$HOME/.config/starship.toml" \
  "$HOME/.config/tmux/tmux.conf" \
  "$HOME/.config/btop/btop.conf" \
  "$HOME/.config/fastfetch/config.jsonc" \
  "$HOME/.config/cava/config" \
  "$HOME/.config/nvim/init.lua" \
  "$HOME/.gitconfig"; do
  check_link "$target"
done

if [[ -f /usr/share/wayland-sessions/hyprland.desktop ]]; then
  info "Hyprland session entry: present"
else
  warn "Hyprland session entry missing: /usr/share/wayland-sessions/hyprland.desktop"
  FAIL=1
fi

if [[ -f /etc/plasmalogin.conf ]] && grep -qE '^\[Autologin\]' /etc/plasmalogin.conf && \
   grep -qE '^User=' /etc/plasmalogin.conf; then
  warn "Plasma Login Manager autologin still configured; the session picker may be skipped."
  FAIL=1
else
  info "Plasma Login Manager autologin: disabled or not configured"
fi

if (( FAIL == 0 )); then
  info "All checks passed."
else
  die "Some checks failed; see the warnings above."
fi
