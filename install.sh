#!/usr/bin/env bash
set -euo pipefail

if [ "$(id -u)" -eq 0 ]; then
  echo "Do not run as root." >&2
  exit 1
fi

if [ ! -f /etc/arch-release ]; then
  echo "This is not Arch Linux." >&2
  exit 1
fi

cd "$(dirname "$0")"

mapfile -t pkgs < <(grep -vE '^\s*(#|$)' packages.txt)

sudo pacman -S --needed "${pkgs[@]}"

echo "Done. Log out and pick the Hyprland session at the login screen. See README."
