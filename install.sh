#!/usr/bin/env bash
# The only user-facing entry point.
#
#   ./install.sh                 base install; enabled.txt modules if present
#   ./install.sh add             pick and install modules
#   ./install.sh adopt <module>  move your real config into the module
#   ./install.sh remove <module> unstow and disable a module
#   ./install.sh host            generate hosts/<hostname>/
#   ./install.sh doctor          kde-guard diff + lint-paths
#   ./install.sh list            show modules and enabled state
#
# It never changes the login shell, /etc, /usr, systemd units, fonts,
# GTK/KDE themes, or the user's environment outside Hyprland's own config.
set -Eeuo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
MODULES_DIR="$REPO_DIR/modules"
BASE_STOW_DIR="$REPO_DIR/base"
HOSTS_DIR="$REPO_DIR/hosts"

# shellcheck source=scripts/lib.sh
source "$REPO_DIR/scripts/lib.sh"
# shellcheck source=scripts/modules.sh
source "$REPO_DIR/scripts/modules.sh"

DRY_RUN=0
ASSUME_YES=0
DO_PACKAGES=1
NONINTERACTIVE=0
MODE=""
MODE_ARG=""
BACKUP_DIR=""

usage() {
  cat <<'EOF'
Usage: ./install.sh [options]
       ./install.sh add
       ./install.sh adopt <module>
       ./install.sh remove <module>
       ./install.sh host
       ./install.sh doctor
       ./install.sh list

Options:
  --dry-run       Show what would happen; change nothing.
  -y, --yes       Assume yes for confirmations (still shows the lists).
  --no-packages   Stow only; do not install packages.
  -h, --help      Show this help.

The plain run installs base/packages.txt (Hyprland + kitty + stow/jq/curl).
If enabled.txt exists, every recorded module and the matching hosts/<hostname>/
package are installed and stowed non-interactively.
EOF
}

while (($#)); do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    -y|--yes) ASSUME_YES=1 ;;
    --no-packages) DO_PACKAGES=0 ;;
    -h|--help) usage; exit 0 ;;
    add) MODE="add" ;;
    host|doctor|list) MODE="$1" ;;
    adopt|remove)
      MODE="$1"
      shift
      (($#)) || die "Usage: ./install.sh $MODE <module>"
      MODE_ARG="$1"
      ;;
    -*) die "Unknown option: $1 (try --help)" ;;
    *) die "Unknown argument: $1 (try --help)" ;;
  esac
  shift
done

[[ "${EUID:-$(id -u)}" -ne 0 ]] || die "Run as your normal user, not root."
is_arch || die "This installer targets Arch Linux / CachyOS only."
have pacman || die "pacman not found."

if [[ -n "$MODE_ARG" ]]; then
  module_validate "$MODE_ARG"
fi

require_stow() {
  (( DRY_RUN )) && return 0
  have stow || die "stow is not installed. Run without --no-packages, or install stow first."
}

read_base_packages() {
  awk 'NF && $1 !~ /^#/ {print $1}' "$REPO_DIR/base/packages.txt"
}

dedupe_lines() {
  awk 'NF && !seen[$0]++'
}

run_lint() {
  "$REPO_DIR/scripts/lint-paths"
}

guard_snapshot() {
  if (( DRY_RUN )); then
    printf '  [dry-run] kde-guard snapshot\n' >&2
    return 0
  fi
  "$REPO_DIR/scripts/kde-guard" snapshot
}

guard_diff() {
  local before="$1" after="$2"
  [[ -n "$before" && -n "$after" ]] || return 0
  if ! "$REPO_DIR/scripts/kde-guard" diff "$before" "$after"; then
    return 1
  fi
}

host_package_name() {
  current_hostname | tr -d '[:space:]'
}

stow_module() {
  local module="$1"
  local -a config_paths=()
  mapfile -t config_paths < <(module_config_paths "$module")
  stow_package "$MODULES_DIR" "$module" "$(module_scope "$module")" "${config_paths[@]}"
}

show_finish() {
  local -a enabled=()
  mapfile -t enabled < <(enabled_modules)
  cat <<EOF

Done.

The Hyprland session entry comes from the hyprland package.
Log out at the login screen and choose Hyprland. KDE Plasma remains selectable.

Enabled modules: ${enabled[*]:-none}
Add a component:  ./install.sh add
Record a config:  ./install.sh adopt <module>
Check KDE state:  ./install.sh doctor
EOF
}

main_base() {
  local -a enabled=() base_pkgs=() module_pkgs=() aur_pkgs=()
  local -a official=() aur=() new_pkgs=()
  local m host_name="" host_pkg="" before_file="" after_file=""
  local guard_before="" guard_after="" guard_failed=0

  if [[ -f "$REPO_DIR/enabled.txt" ]]; then
    NONINTERACTIVE=1
    mapfile -t enabled < <(enabled_modules)
  fi

  mapfile -t base_pkgs < <(read_base_packages)
  for m in "${enabled[@]}"; do
    module_validate "$m"
    while IFS= read -r p; do module_pkgs+=("$p"); done < <(module_packages "$m")
    while IFS= read -r p; do aur_pkgs+=("$p"); done < <(module_aur_packages "$m")
  done

  mapfile -t official < <(
    {
      printf '%s\n' "${base_pkgs[@]}"
      printf '%s\n' "${module_pkgs[@]}"
    } | dedupe_lines
  )
  mapfile -t aur < <(printf '%s\n' "${aur_pkgs[@]}" | dedupe_lines)

  host_name="$(host_package_name)"
  if [[ -n "$host_name" && -d "$HOSTS_DIR/$host_name" ]]; then
    host_pkg="$host_name"
  fi

  run_lint
  if ! guard_before="$(guard_snapshot)"; then
    warn "kde-guard before snapshot failed; continuing without it."
    guard_before=""
  fi

  if (( DO_PACKAGES )); then
    keep_sudo_alive
    preview_packages "${official[@]}"
    red_flag_check "${official[@]}"
    if (( ! NONINTERACTIVE && ! ASSUME_YES )); then
      confirm "Proceed with the base install and the modules in enabled.txt?" || die "Aborted by user."
    fi
    before_file="$(mktemp)"
    pacman -Qq | sort > "$before_file"
    install_packages "${official[@]}"
    if ((${#aur[@]})); then
      aur_install "${aur[@]}"
    fi
    after_file="$(mktemp)"
    pacman -Qq | sort > "$after_file"
    mapfile -t new_pkgs < <(comm -13 "$before_file" "$after_file")
    rm -f -- "$before_file" "$after_file"
    if ((${#new_pkgs[@]})); then
      red_flag_installed "${new_pkgs[@]}"
    fi
  else
    info "Skipping package installation (--no-packages)."
  fi

  require_stow
  stow_package "$BASE_STOW_DIR" hypr scoped .config/hypr/hyprland.lua
  for m in "${enabled[@]}"; do
    stow_module "$m"
  done
  if [[ -n "$host_pkg" ]]; then
    info "Stowing host package: $host_pkg"
    stow_package "$HOSTS_DIR" "$host_pkg" scoped \
      .config/hypr/host.lua .config/waybar/host.jsonc
  fi

  notice_autologin
  if ! guard_after="$(guard_snapshot)"; then
    warn "kde-guard after snapshot failed; continuing without it."
    guard_after=""
  fi
  if ! guard_diff "$guard_before" "$guard_after"; then
    guard_failed=1
  fi
  if ! run_lint; then
    guard_failed=1
  fi
  show_finish
  if (( guard_failed )); then
    err "One or more checks failed. Review the kde-guard/lint-paths output above."
    exit 1
  fi
}

main_add() {
  local -a selected=() pkgs=() aur_pkgs=() new_pkgs=()
  local m before_file="" after_file=""
  local guard_before="" guard_after="" guard_failed=0

  mapfile -t selected < <(choose_modules)
  if ((${#selected[@]} == 0)); then
    info "No modules selected."
    return 0
  fi

  run_lint
  if ! guard_before="$(guard_snapshot)"; then
    warn "kde-guard before snapshot failed; continuing without it."
    guard_before=""
  fi
  require_stow
  if (( DO_PACKAGES )); then
    keep_sudo_alive
  fi

  for m in "${selected[@]}"; do
    module_validate "$m"
    if is_module_enabled "$m"; then
      info "Module already enabled: $m (restowing)"
    fi
    if [[ "$(module_scope "$m")" == "shared" ]]; then
      warn "Shared module: $m is reachable from KDE too. A conflict will abort; changes may be visible in KDE."
    fi
    pkgs=()
    aur_pkgs=()
    mapfile -t pkgs < <(module_packages "$m")
    mapfile -t aur_pkgs < <(module_aur_packages "$m")
    if (( DO_PACKAGES )); then
      if ((${#pkgs[@]})); then
        preview_packages "${pkgs[@]}"
        red_flag_check "${pkgs[@]}"
        if (( ! ASSUME_YES )); then
          confirm "Install packages for $m?" || die "Aborted by user."
        fi
        before_file="$(mktemp)"
        pacman -Qq | sort > "$before_file"
        install_packages "${pkgs[@]}"
        after_file="$(mktemp)"
        pacman -Qq | sort > "$after_file"
        mapfile -t new_pkgs < <(comm -13 "$before_file" "$after_file")
        rm -f -- "$before_file" "$after_file"
        if ((${#new_pkgs[@]})); then
          red_flag_installed "${new_pkgs[@]}"
        fi
      fi
      if ((${#aur_pkgs[@]})); then
        aur_install "${aur_pkgs[@]}"
      fi
    else
      info "Skipping packages for $m (--no-packages)."
    fi
    stow_module "$m"
    if (( DRY_RUN )); then
      info "[dry-run] enable module: $m"
    else
      enable_module "$m"
    fi
  done

  if ! guard_after="$(guard_snapshot)"; then
    warn "kde-guard after snapshot failed; continuing without it."
    guard_after=""
  fi
  if ! guard_diff "$guard_before" "$guard_after"; then
    guard_failed=1
  fi
  if ! run_lint; then
    guard_failed=1
  fi
  info "Configure your new component normally, then run ./install.sh adopt <module>."
  if (( guard_failed )); then
    err "One or more checks failed. Review the output above."
    exit 1
  fi
}

main_adopt() {
  local module="$MODE_ARG" scope path rel src dest resolved file
  local -a config_paths=() srcs=() rels=()
  local -a moved_src=() moved_dest=()

  module_validate "$module"
  require_stow
  scope="$(module_scope "$module")"
  mapfile -t config_paths < <(module_config_paths "$module")
  ((${#config_paths[@]})) || die "Module '$module' declares no config_paths; nothing can be adopted."
  if [[ "$scope" == "shared" ]]; then
    warn "Shared module: adopted files are reachable from KDE too."
  fi

  for path in "${config_paths[@]}"; do
    path="$HOME/$path"
    if [[ -L "$path" ]]; then
      resolved="$(readlink -f -- "$path" 2>/dev/null || true)"
      if [[ -n "$resolved" && "$resolved" == "$REPO_DIR"/* ]]; then
        info "Already stowed from the repo: ${path#"$HOME"/}"
        continue
      fi
      die "Refusing to adopt symlink outside the repo: $path -> ${resolved:-broken link}"
    fi
    if [[ ! -e "$path" ]]; then
      info "Not present, nothing to adopt: ${path#"$HOME"/}"
      continue
    fi
    if [[ -d "$path" ]]; then
      while IFS= read -r -d '' file; do
        srcs+=("$file")
        rels+=("${file#"$HOME/"}")
      done < <(find "$path" -mindepth 1 \( -type f -o -type l \) -print0)
    else
      srcs+=("$path")
      rels+=("${path#"$HOME"/}")
    fi
  done

  ((${#srcs[@]})) || { info "Nothing to adopt for $module."; return 0; }

  for rel in "${rels[@]}"; do
    local found=0 p
    for p in "${config_paths[@]}"; do
      if path_in_config_paths "$rel" "$p"; then found=1; break; fi
    done
    ((found)) || die "Refusing to adopt path outside config_paths: $rel"
  done

  for src in "${srcs[@]}"; do
    rel="${src#"$HOME/"}"
    dest="$MODULES_DIR/$module/$rel"
    if [[ -L "$src" ]]; then
      resolved="$(readlink -f -- "$src" 2>/dev/null || true)"
      if [[ -n "$resolved" && "$resolved" == "$REPO_DIR"/* ]]; then
        continue
      fi
      die "Refusing to adopt symlink outside the repo: $src -> ${resolved:-broken link}"
    fi
    if [[ -e "$dest" ]]; then
      if [[ -f "$src" && -f "$dest" ]] && cmp -s -- "$src" "$dest"; then
        continue
      fi
      die "Adopt conflict: $dest already exists and differs from $src."
    fi
  done

  if (( DRY_RUN )); then
    for src in "${srcs[@]}"; do
      rel="${src#"$HOME/"}"
      if [[ -L "$src" ]]; then
        resolved="$(readlink -f -- "$src" 2>/dev/null || true)"
        [[ -n "$resolved" && "$resolved" == "$REPO_DIR"/* ]] && continue
      fi
      info "[dry-run] would move ~/$rel -> modules/$module/$rel"
    done
    info "[dry-run] would stow module $module after moving the files"
    return 0
  fi

  for src in "${srcs[@]}"; do
    rel="${src#"$HOME/"}"
    dest="$MODULES_DIR/$module/$rel"
    if [[ -L "$src" ]]; then
      resolved="$(readlink -f -- "$src" 2>/dev/null || true)"
      if [[ -n "$resolved" && "$resolved" == "$REPO_DIR"/* ]]; then
        continue
      fi
    fi
    if [[ -e "$dest" ]]; then
      rm -f -- "$src"
      continue
    fi
    mkdir -p -- "$(dirname -- "$dest")"
    mv -- "$src" "$dest"
    moved_src+=("$src")
    moved_dest+=("$dest")
    info "Adopted ${rel} -> modules/$module/$rel"
  done

  if ! ( stow_module "$module" ); then
    local i
    for i in "${!moved_src[@]}"; do
      mkdir -p -- "$(dirname -- "${moved_src[$i]}")"
      mv -- "${moved_dest[$i]}" "${moved_src[$i]}"
    done
    die "stow failed after adopt; moved files were restored."
  fi
  if ! is_module_enabled "$module"; then
    enable_module "$module"
  fi
  run_lint
}

main_remove() {
  local module="$MODE_ARG"
  local -a pkgs=() removable=() other_pkgs=()
  local p m keep

  module_validate "$module"
  require_stow
  unstow_package "$MODULES_DIR" "$module"
  if (( DRY_RUN )); then
    info "[dry-run] disable module: $module"
  else
    disable_module "$module"
  fi

  mapfile -t pkgs < <(module_packages "$module")
  ((${#pkgs[@]})) || return 0
  info "Packages recorded by $module: ${pkgs[*]}"

  if (( ! DO_PACKAGES )); then
    info "Skipping package removal (--no-packages)."
    return 0
  fi

  mapfile -t other_pkgs < <(
    {
      read_base_packages
      while IFS= read -r m; do
        [[ "$m" == "$module" ]] && continue
        module_packages "$m"
      done < <(enabled_modules)
    } | dedupe_lines
  )

  for p in "${pkgs[@]}"; do
    keep=0
    for m in "${other_pkgs[@]}"; do
      [[ "$p" == "$m" ]] && { keep=1; break; }
    done
    ((keep)) || removable+=("$p")
  done

  if ((${#removable[@]} == 0)); then
    info "No module-exclusive packages to remove."
    return 0
  fi
  info "Module-exclusive packages: ${removable[*]}"
  warn "Package removal is never automatic. 'pacman -R' is used without -s/-n so dependencies stay installed."
  if (( DRY_RUN )); then
    run_sudo pacman -R -- "${removable[@]}"
    return 0
  fi
  if ! confirm "Uninstall these packages now?"; then
    info "Packages kept."
    return 0
  fi
  local -a cmd=(pacman -R)
  (( ASSUME_YES )) && cmd+=(--noconfirm)
  cmd+=("${removable[@]}")
  run_sudo "${cmd[@]}"
}

main_list() {
  local m scope enabled
  printf '%-12s %-7s %-14s %-7s %s\n' "MODULE" "SCOPE" "CATEGORY" "ENABLED" "PACKAGES"
  while IFS= read -r m; do
    module_validate "$m"
    scope="$(module_scope "$m")"
    enabled="no"
    is_module_enabled "$m" && enabled="yes"
    printf '%-12s %-7s %-14s %-7s %s\n' \
      "$m" "$scope" "$(module_field "$m" category)" "$enabled" \
      "$(module_packages "$m" | paste -sd ', ' -)"
  done < <(module_names)
}

main_doctor() {
  local rc=0
  run_lint || rc=1
  if ! "$REPO_DIR/scripts/kde-guard" diff; then
    rc=1
  fi
  if (( rc )); then
    err "doctor found issues; review the output above."
    exit 1
  fi
  info "doctor: no unexplained diffs and no lint violations."
}

main_host() {
  local -a args=()
  (( DRY_RUN )) && args+=(--dry-run)
  (( ASSUME_YES )) && args+=(--yes)
  "$REPO_DIR/scripts/host.sh" "${args[@]}"
}

case "$MODE" in
  "") main_base ;;
  add) main_add ;;
  adopt) main_adopt ;;
  remove) main_remove ;;
  host) main_host ;;
  doctor) main_doctor ;;
  list) main_list ;;
  *) die "Unknown mode: $MODE" ;;
esac
