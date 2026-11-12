#!/usr/bin/env bash
set -Eeuo pipefail

selection="$(cliphist list | wofi --dmenu --prompt "Clipboard" --width 700 --height 500)"
[[ -n "${selection:-}" ]] || exit 0
printf '%s' "$selection" | cliphist decode | wl-copy
