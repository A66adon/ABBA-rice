#!/usr/bin/env bash
# Generate the Catppuccin Mocha wallpaper used by Hyprpaper and Hyprlock.
set -Eeuo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$REPO_DIR/hypr/.config/hypr/wallpapers/catppuccin-mocha.png"

if ! command -v magick >/dev/null 2>&1; then
  echo "ImageMagick (magick) is required: sudo pacman -S imagemagick" >&2
  exit 1
fi

mkdir -p "$(dirname "$OUT")"

# 2560x1440 keeps the repository small while still looking sharp on the
# 2560x1440 monitors. Soft mauve/blue/pink glows over a dark base.
magick -size 2560x1440 gradient:'#1e1e2e-#181825' \
  \( -size 2560x1440 xc:none -fill '#cba6f7' -draw 'circle 2050,320 2050,620' -blur 0x140 \) -compose over -composite \
  \( -size 2560x1440 xc:none -fill '#89b4fa' -draw 'circle 420,1120 420,1420' -blur 0x160 \) -compose over -composite \
  \( -size 2560x1440 xc:none -fill '#f5c2e7' -draw 'circle 1280,720 1280,900' -blur 0x180 \) -compose over -composite \
  "$OUT"

printf 'Wrote %s\n' "$OUT"
