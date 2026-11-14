#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

for dir in stow/*/; do
  [ -d "$dir" ] || continue
  name=${dir#stow/}
  name=${name%/}
  if ! stow -R --no-folding -d stow -t "$HOME" "$name"; then
    echo "A real file is in the way. Move it yourself." >&2
    exit 1
  fi
done
