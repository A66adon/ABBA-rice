#!/usr/bin/env bash
set -Eeuo pipefail

dir="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
mkdir -p "$dir"
file="$dir/$(date +%Y-%m-%d_%H-%M-%S)_region.png"

grim -g "$(slurp)" "$file"
wl-copy < "$file"

if command -v notify-send >/dev/null 2>&1; then
  notify-send -a Screenshot "Region screenshot" "$file"
fi
