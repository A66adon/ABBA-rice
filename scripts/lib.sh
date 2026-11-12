#!/usr/bin/env bash
# Shared helpers for the dotfiles installer, verifier, and restore script.

info() { printf '\033[1;34m::\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }
err()  { printf '\033[1;31m!!\033[0m %s\n' "$*" >&2; }
die()  { err "$*"; exit 1; }

have() { command -v "$1" >/dev/null 2>&1; }

is_arch() {
  [[ -r /etc/os-release ]] || return 1
  # shellcheck disable=SC1091
  . /etc/os-release
  [[ "${ID:-}" == "cachyos" || "${ID_LIKE:-}" == *arch* ]]
}

run() {
  if (( ${DRY_RUN:-0} )); then
    printf '  [dry-run]'
    printf ' %q' "$@"
    printf '\n'
    return 0
  fi
  "$@"
}

run_sudo() {
  if (( ${DRY_RUN:-0} )); then
    printf '  [dry-run] sudo'
    printf ' %q' "$@"
    printf '\n'
    return 0
  fi
  sudo "$@"
}

confirm() {
  (( ${ASSUME_YES:-0} )) && return 0
  local reply
  read -r -p "${1:-Continue?} [y/N] " reply
  [[ "$reply" =~ ^[Yy]$ ]]
}

keep_sudo_alive() {
  (( ${DRY_RUN:-0} )) && return 0
  have sudo || die "sudo is required for package installation."
  sudo -v || die "sudo authentication failed."
  ( while true; do sudo -n true; sleep 60; kill -0 "$$" 2>/dev/null || exit; done ) &
  SUDO_KEEPALIVE_PID=$!
  trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true' EXIT
}

# Print the $HOME paths that a set of Stow packages would create.
repo_targets() {
  local pkg rel
  for pkg in "$@"; do
    [[ -d "$REPO_DIR/$pkg" ]] || continue
    while IFS= read -r -d '' file; do
      rel="${file#"$REPO_DIR/$pkg/"}"
      printf '%s\n' "$HOME/$rel"
    done < <(find "$REPO_DIR/$pkg" -type f -print0)
  done
}
