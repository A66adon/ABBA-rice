#!/usr/bin/env bash
# Shared helpers for install.sh and the scripts/ helpers.
#
# This file is sourced. It intentionally does not enable shell options.

info() { printf '\033[1;34m::\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }
err()  { printf '\033[1;31m!!\033[0m %s\n' "$*" >&2; }
die()  { err "$*"; exit 1; }

have() { command -v -- "$1" >/dev/null 2>&1; }

is_arch() {
  [[ -r /etc/os-release ]] || return 1
  # shellcheck disable=SC1091
  . /etc/os-release
  [[ "${ID:-}" == "arch" || "${ID:-}" == "cachyos" || "${ID_LIKE:-}" == *arch* ]]
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
  read -r -p "${1:-Continue?} [y/N] " reply || return 1
  [[ "$reply" =~ ^[Yy]$ ]]
}

keep_sudo_alive() {
  (( ${DRY_RUN:-0} )) && return 0
  have sudo || die "sudo is required for package installation."
  sudo -v || die "sudo authentication failed."
  ( while true; do sudo -n true; sleep 60; kill -0 "$$" 2>/dev/null || exit; done ) &
  SUDO_KEEPALIVE_PID=$!
  trap 'kill "${SUDO_KEEPALIVE_PID:-}" 2>/dev/null || true' EXIT
}

repo_state_root() {
  printf '%s/%s\n' "${XDG_STATE_HOME:-$HOME/.local/state}" "$(basename -- "$REPO_DIR")"
}

backup_root() {
  printf '%s/backup\n' "$(repo_state_root)"
}

new_backup_dir() {
  local base ts dir n=1
  base="$(backup_root)"
  ts="$(date +%Y%m%d-%H%M%S)"
  dir="$base/$ts"
  while [[ -e "$dir" ]]; do
    dir="$base/$ts-$n"
    ((n++))
  done
  printf '%s\n' "$dir"
}

timestamp() {
  date +%Y%m%d-%H%M%S
}

current_hostname() {
  uname -n 2>/dev/null || cat /proc/sys/kernel/hostname 2>/dev/null || printf 'unknown\n'
}

path_in_config_paths() {
  local rel="$1"
  shift
  local p
  for p in "$@"; do
    [[ -n "$p" ]] || continue
    p="${p%/}"
    if [[ "$rel" == "$p" || "$rel" == "$p/"* ]]; then
      return 0
    fi
  done
  return 1
}

package_targets() {
  local stow_dir="$1" pkg="$2" root file rel
  root="$stow_dir/$pkg"
  [[ -d "$root" ]] || return 0
  while IFS= read -r -d '' file; do
    rel="${file#"$root/"}"
    [[ "$rel" == "module.conf" ]] && continue
    printf '%s\n' "$rel"
  done < <(find "$root" -mindepth 1 \( -type f -o -type l \) -print0 | sort -z)
}

package_has_payload() {
  local stow_dir="$1" pkg="$2" root
  root="$stow_dir/$pkg"
  [[ -d "$root" ]] || return 1
  find "$root" -mindepth 1 \( -type f -o -type l \) -not -name module.conf -print -quit | grep -q .
}

backup_conflict() {
  local rel="$1" pkg="$2" target dest
  target="$HOME/$rel"
  if (( ${DRY_RUN:-0} )); then
    info "  would back up ~/$rel"
    return 0
  fi
  if [[ -z "${BACKUP_DIR:-}" ]]; then
    BACKUP_DIR="$(new_backup_dir)"
  fi
  dest="$BACKUP_DIR/$rel"
  mkdir -p -- "$(dirname -- "$dest")"
  mv -- "$target" "$dest"
  printf '%s\t%s\t%s\n' "$target" "$dest" "$pkg" >> "$BACKUP_DIR/manifest.tsv"
  info "  backed up ~/$rel"
}

# stow_package <stow-dir> <package> <scoped|shared> [config_path ...]
# Simulates first, backs up only regular files inside a scoped config path,
# and aborts for everything else. module.conf is metadata, never stowed.
stow_package() {
  local stow_dir="$1" pkg="$2" scope="$3"
  shift 3
  local -a config_paths=("$@")
  local root="$stow_dir/$pkg" file rel target resolved pkg_real
  local -a cmd conflicts=() backed_up=()

  [[ -d "$root" ]] || die "Unknown stow package: $root"
  if ! package_has_payload "$stow_dir" "$pkg"; then
    info "No stow payload for $pkg; skipping stow."
    return 0
  fi
  pkg_real="$(readlink -f -- "$root")"

  # Preflight every target before moving anything.
  while IFS= read -r file; do
    rel="${file#"$root/"}"
    target="$HOME/$rel"

    if [[ -L "$target" ]]; then
      resolved="$(readlink -f -- "$target" 2>/dev/null || true)"
      if [[ -n "$resolved" && "$resolved" == "$pkg_real"/* ]]; then
        continue
      fi
      if [[ -n "$resolved" && "$resolved" == "$REPO_DIR"/* ]]; then
        die "Conflict: ~/$rel points into another repo package ($resolved); refusing to overwrite it."
      fi
      die "Conflict: ~/$rel is a symlink outside the repo; refusing to move or replace it."
    fi

    if [[ -e "$target" ]]; then
      if [[ ! -f "$target" ]]; then
        die "Conflict: ~/$rel is not a regular file; refusing to replace it."
      fi
      if [[ "$scope" == "scoped" ]] && path_in_config_paths "$rel" "${config_paths[@]}"; then
        conflicts+=("$rel")
      else
        die "Conflict: ~/$rel already exists and is not a scoped module path. Move it yourself, then retry."
      fi
    fi
  done < <(package_targets "$stow_dir" "$pkg")

  if (( ${DRY_RUN:-0} )); then
    for rel in "${conflicts[@]}"; do
      info "  would back up ~/$rel"
    done
    cmd=(stow --dir="$stow_dir" --target="$HOME" --no-folding --ignore='module[.]conf' --restow "$pkg")
    run "${cmd[@]}"
    return 0
  fi

  for rel in "${conflicts[@]}"; do
    backup_conflict "$rel" "$pkg"
    backed_up+=("$rel")
  done

  restore_backups() {
    local r dest target tmp_manifest targets_file
    for r in "${backed_up[@]}"; do
      dest="$BACKUP_DIR/$r"
      target="$HOME/$r"
      [[ -e "$dest" || -L "$dest" ]] || continue
      mkdir -p -- "$(dirname -- "$target")"
      if [[ -L "$target" ]]; then
        rm -f -- "$target"
      fi
      mv -- "$dest" "$target"
    done
    if [[ -f "$BACKUP_DIR/manifest.tsv" ]]; then
      tmp_manifest="$(mktemp)"
      targets_file="$(mktemp)"
      for r in "${backed_up[@]}"; do
        printf '%s\n' "$HOME/$r"
      done > "$targets_file"
      awk -v targetsfile="$targets_file" '
        BEGIN { while ((getline line < targetsfile) > 0) restored[line] = 1 }
        !($1 in restored) { print }
      ' "$BACKUP_DIR/manifest.tsv" > "$tmp_manifest"
      mv -- "$tmp_manifest" "$BACKUP_DIR/manifest.tsv"
      rm -f -- "$targets_file"
    fi
  }

  cmd=(stow --dir="$stow_dir" --target="$HOME" --no-folding --ignore='module[.]conf' --restow "$pkg")
  if ! stow --dir="$stow_dir" --target="$HOME" --no-folding --ignore='module[.]conf' --restow --simulate "$pkg"; then
    restore_backups
    die "stow simulation failed for $pkg; backups were restored."
  fi
  if ! "${cmd[@]}"; then
    stow --dir="$stow_dir" --target="$HOME" --no-folding --ignore='module[.]conf' -D "$pkg" >/dev/null 2>&1 || true
    restore_backups
    die "stow failed for $pkg; backups were restored."
  fi
  info "Stowed $pkg."
}

unstow_package() {
  local stow_dir="$1" pkg="$2"
  [[ -d "$stow_dir/$pkg" ]] || return 0
  if (( ${DRY_RUN:-0} )); then
    run stow --dir="$stow_dir" --target="$HOME" --no-folding --ignore='module[.]conf' -D "$pkg"
    return 0
  fi
  if ! stow --dir="$stow_dir" --target="$HOME" --no-folding --ignore='module[.]conf' -D "$pkg"; then
    die "Failed to unstow $pkg."
  fi
  info "Unstowed $pkg."
}

package_is_installed() {
  pacman -Q -- "$1" >/dev/null 2>&1
}

package_version() {
  pacman -Q -- "$1" 2>/dev/null | awk '{print $2; exit}'
}

preview_packages() {
  local -a pkgs=("$@")
  ((${#pkgs[@]})) || return 0
  local line name ver installed sp_output
  local -a new_pkgs=() upgraded=() transaction=()
  if ! sp_output="$(pacman -Sp --print-format '%n|%v' -- "${pkgs[@]}" 2>/dev/null)"; then
    printf '%s\n' "$sp_output" >&2
    die "pacman could not prepare the transaction. Run 'sudo pacman -Syu' first; this repo never does partial upgrades."
  fi
  mapfile -t transaction <<< "$sp_output"
  for line in "${transaction[@]}"; do
    [[ "$line" == *"|"* ]] || continue
    name="${line%%|*}"
    ver="${line#*|}"
    [[ "$name" =~ ^[A-Za-z0-9@._+:-]+$ ]] || continue
    if installed="$(package_version "$name")" && [[ -n "$installed" ]]; then
      if [[ "$installed" != "$ver" ]]; then
        upgraded+=("$name $installed -> $ver")
      fi
    else
      new_pkgs+=("$name $ver")
    fi
  done
  info "Requested packages: ${pkgs[*]}"
  if ((${#new_pkgs[@]})); then
    info "New packages:"
    printf '  %s\n' "${new_pkgs[@]}"
  fi
  if ((${#upgraded[@]})); then
    info "Packages that would be upgraded:"
    printf '  %s\n' "${upgraded[@]}"
  fi
  if ((${#new_pkgs[@]} == 0 && ${#upgraded[@]} == 0)); then
    info "All requested packages are already installed at the target versions."
  fi
  info "Total package transaction entries: ${#transaction[@]}"
}

aur_helper() {
  if have paru; then
    printf 'paru\n'
  elif have yay; then
    printf 'yay\n'
  fi
}

aur_install() {
  local -a pkgs=("$@")
  ((${#pkgs[@]})) || return 0
  local helper pkg
  helper="$(aur_helper)"
  if [[ -z "$helper" ]]; then
    warn "No AUR helper (paru/yay) found; skipping: ${pkgs[*]}"
    return 0
  fi
  for pkg in "${pkgs[@]}"; do
    info "AUR package: $pkg"
    "$helper" -Si "$pkg" 2>/dev/null | sed -n '1,18p' || true
    if (( ${NONINTERACTIVE:-0} && ! ${ASSUME_YES:-0} )); then
      warn "Skipping AUR package $pkg in non-interactive mode; run ./install.sh add or pass --yes."
      continue
    fi
    if ! (( ${ASSUME_YES:-0} )); then
      confirm "Install AUR package $pkg with $helper?" || { warn "Skipping AUR package $pkg."; continue; }
    fi
    if (( ${DRY_RUN:-0} )); then
      run "$helper" -S --needed "$pkg"
    elif (( ${ASSUME_YES:-0} )); then
      "$helper" -S --needed --noconfirm "$pkg"
    else
      "$helper" -S --needed "$pkg"
    fi
    if (( ! ${DRY_RUN:-0} )); then
      red_flag_installed "$pkg"
    fi
  done
}

install_packages() {
  local -a pkgs=("$@")
  ((${#pkgs[@]})) || return 0
  local -a cmd=(pacman -S --needed)
  (( ${ASSUME_YES:-0} )) && cmd+=(--noconfirm)
  cmd+=("${pkgs[@]}")
  run_sudo "${cmd[@]}"
}

ensure_files_db() {
  local pkg="${1:-}"
  [[ -n "$pkg" ]] || return 1
  if pacman -Fl -- "$pkg" >/dev/null 2>&1; then
    return 0
  fi
  warn "The pacman files database is missing, so 'pacman -Fl' cannot inspect package files."
  if (( ${DRY_RUN:-0} )); then
    warn "Dry run: skipping the red-flag file inspection."
    return 1
  fi
  if (( ${ASSUME_YES:-0} || ${NONINTERACTIVE:-0} )); then
    info "Downloading pacman file lists for the mandated pre-install check..."
    run_sudo pacman -Fy
  elif confirm "Run 'sudo pacman -Fy' to download file lists (this is not a package upgrade)?"; then
    run_sudo pacman -Fy
  else
    die "Cannot inspect package files. Run 'sudo pacman -Fy' and retry."
  fi
  if pacman -Fl -- "$pkg" >/dev/null 2>&1; then
    return 0
  fi
  die "Cannot inspect package files. Run 'sudo pacman -Fy' and retry."
}

red_flag_patterns() {
  printf '%s\n' \
    '/etc/xdg/autostart/' \
    '/usr/lib/systemd/user/' \
    '/usr/lib/systemd/system/' \
    '/usr/share/dbus-1/services/' \
    '/usr/share/dbus-1/system-services/' \
    '/etc/profile.d/' \
    '/usr/lib/environment.d/' \
    '/etc/fonts/conf.d/' \
    '/usr/share/fontconfig/' \
    '/usr/lib/udev/rules.d/' \
    '/usr/lib/modprobe.d/' \
    '/etc/pam.d/' \
    '/usr/share/mime/packages/'
}

red_flag_match() {
  local path="$1" pat
  while IFS= read -r pat; do
    [[ "$path" == "$pat"* ]] && return 0
  done < <(red_flag_patterns)
  return 1
}

package_archive() {
  local pkg="$1" cache url file
  have curl || return 2
  cache="${TMPDIR:-/tmp}/abba-rice-redflag"
  mkdir -p -- "$cache"
  url="$(pacman -Sp --print-format '%l' -- "$pkg" 2>/dev/null | tail -n1)"
  [[ -n "$url" ]] || return 2
  file="$cache/${url##*/}"
  if [[ ! -f "$file" ]]; then
    curl -fsSL --retry 2 -o "$file" "$url" || return 2
  fi
  printf '%s\n' "$file"
}

extract_package_file() {
  local archive="$1" path="$2"
  path="${path#/}"
  if have bsdtar; then
    bsdtar -xOf "$archive" "$path" 2>/dev/null
  elif have tar; then
    tar --zstd -xOf "$archive" "$path" 2>/dev/null
  else
    return 2
  fi
}

# Returns 0 when the autostart entry is visible in KDE, 1 when it is
# explicitly restricted to other desktops, 2 when it cannot be inspected.
desktop_starts_in_kde() {
  local pkg="$1" path="$2" archive content only notshow
  archive="$(package_archive "$pkg")" || return 2
  content="$(extract_package_file "$archive" "$path")" || return 2
  only="$(printf '%s\n' "$content" | sed -n 's/^OnlyShowIn=//p' | head -n1)"
  notshow="$(printf '%s\n' "$content" | sed -n 's/^NotShowIn=//p' | head -n1)"
  if [[ -n "$notshow" && "$notshow" == *KDE* ]]; then
    return 1
  fi
  if [[ -n "$only" ]]; then
    if [[ "$only" == *KDE* ]]; then
      return 0
    fi
    return 1
  fi
  return 0
}

# red_flag_check <package...>
# Prints every risky path, aborts on KDE-visible autostart/tray entries,
# and asks for confirmation for the rest.
red_flag_check() {
  local -a pkgs=("$@")
  ((${#pkgs[@]})) || return 0
  if ! ensure_files_db "${pkgs[0]}"; then
    return 0
  fi
  local line pkg path flagged=0
  local forbidden=0
  while IFS=$'\t' read -r pkg path; do
    [[ -n "$pkg" && -n "$path" ]] || continue
    [[ "$path" == /* ]] || path="/$path"
    red_flag_match "$path" || continue
    if [[ "$path" == /etc/xdg/autostart/*.desktop ]]; then
      local kde_status=0
      desktop_starts_in_kde "$pkg" "$path" || kde_status=$?
      if (( kde_status == 0 )); then
        err "FORBIDDEN KDE-visible autostart entry: $pkg $path"
        forbidden=1
        continue
      elif (( kde_status == 2 )); then
        err "Could not inspect autostart entry; treating it as forbidden: $pkg $path"
        forbidden=1
        continue
      fi
      info "Autostart entry is restricted away from KDE: $pkg $path"
    else
      printf '  %s: %s\n' "$pkg" "$path"
    fi
    flagged=1
  done < <(pacman -Fl -- "${pkgs[@]}" 2>/dev/null | awk '{print $1 "\t" $2}')
  if (( forbidden )); then
    die "Refusing to install a package that would autostart a KDE-visible tray applet."
  fi
  if (( flagged )); then
    if (( ${NONINTERACTIVE:-0} )) || (( ${ASSUME_YES:-0} )); then
      info "Red-flag list shown; enabled.txt/--yes is treated as prior approval."
    else
      confirm "Proceed with the package files listed above?" || die "Aborted by user."
    fi
  else
    info "No autostart/systemd/dbus/font/udev/PAM/mime files flagged for these packages."
  fi
}

# red_flag_installed <package...>
# Post-install view using pacman -Qlq; informational and cannot prevent an
# already-finished transaction.
red_flag_installed() {
  local -a pkgs=("$@")
  ((${#pkgs[@]})) || return 0
  local pkg path
  for pkg in "${pkgs[@]}"; do
    package_is_installed "$pkg" || continue
    while IFS= read -r path; do
      [[ -n "$path" ]] || continue
      red_flag_match "$path" || continue
      printf '  installed: %s: %s\n' "$pkg" "$path"
      if [[ "$path" == /etc/xdg/autostart/*.desktop && -r "$path" ]]; then
        local only notshow
        only="$(sed -n 's/^OnlyShowIn=//p' "$path" | head -n1)"
        notshow="$(sed -n 's/^NotShowIn=//p' "$path" | head -n1)"
        if [[ -z "$notshow" || "$notshow" != *KDE* ]]; then
          if [[ -z "$only" || "$only" == *KDE* ]]; then
            err "Installed autostart entry is KDE-visible: $path"
          fi
        fi
      fi
    done < <(pacman -Qlq -- "$pkg")
  done
}

detect_login_manager() {
  if systemctl is-active --quiet plasmalogin.service 2>/dev/null || [[ -f /etc/plasmalogin.conf ]]; then
    printf 'plasmalogin\n'
  elif systemctl is-active --quiet sddm.service 2>/dev/null || [[ -f /etc/sddm.conf ]]; then
    printf 'sddm\n'
  elif systemctl is-active --quiet gdm.service 2>/dev/null || [[ -f /etc/gdm/custom.conf ]]; then
    printf 'gdm\n'
  else
    printf 'unknown\n'
  fi
}

autologin_configured() {
  local dm="$1"
  case "$dm" in
    plasmalogin)
      [[ -r /etc/plasmalogin.conf ]] || return 1
      awk '
        /^\[Autologin\]/ { in_auto = 1; next }
        /^\[/ { in_auto = 0 }
        in_auto && /^User=/ { found = 1 }
        END { exit(found ? 0 : 1) }
      ' /etc/plasmalogin.conf
      ;;
    sddm)
      local f
      for f in /etc/sddm.conf /etc/sddm.conf.d/*.conf; do
        [[ -r "$f" ]] || continue
        awk '
          /^\[Autologin\]/ { in_auto = 1; next }
          /^\[/ { in_auto = 0 }
          in_auto && /^User=/ { found = 1 }
          END { exit(found ? 0 : 1) }
        ' "$f" && return 0
      done
      return 1
      ;;
    gdm)
      [[ -r /etc/gdm/custom.conf ]] || return 1
      grep -qE '^[[:space:]]*AutomaticLogin(Enable)?[[:space:]]*=' /etc/gdm/custom.conf
      ;;
    *)
      return 1
      ;;
  esac
}

notice_autologin() {
  local dm
  dm="$(detect_login_manager)"
  if [[ "$dm" == "unknown" ]]; then
    info "Could not identify the login manager; no autologin check was possible."
    return 0
  fi
  if autologin_configured "$dm"; then
    warn "Autologin appears to be enabled for $dm. The session picker may be skipped."
    warn "Disable autologin yourself in KDE's login-manager settings; this repo never edits it."
  else
    info "Autologin does not appear to be enabled for $dm; the session picker should appear."
  fi
}
