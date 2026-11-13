#!/usr/bin/env bash
# Module manifest helpers. Sourced by install.sh and the generator scripts.

module_file() {
  printf '%s/%s/module.conf\n' "${MODULES_DIR:-$REPO_DIR/modules}" "$1"
}

module_names() {
  local dir="${MODULES_DIR:-$REPO_DIR/modules}"
  [[ -d "$dir" ]] || return 0
  find "$dir" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort
}

module_exists() {
  [[ -f "$(module_file "$1")" ]]
}

module_field() {
  local name="$1" field="$2" file
  file="$(module_file "$name")"
  [[ -r "$file" ]] || return 1
  (
    # shellcheck disable=SC1090
    source "$file"
    printf '%s' "${!field-}"
  )
}

module_packages() {
  local name="$1" value
  value="$(module_field "$name" pacman)"
  local -a pkgs=()
  read -r -a pkgs <<< "$value"
  local p
  for p in "${pkgs[@]}"; do
    [[ -n "$p" ]] && printf '%s\n' "$p"
  done
}

module_aur_packages() {
  local name="$1" value
  value="$(module_field "$name" aur)"
  local -a pkgs=()
  read -r -a pkgs <<< "$value"
  local p
  for p in "${pkgs[@]}"; do
    [[ -n "$p" ]] && printf '%s\n' "$p"
  done
}

module_scope() {
  module_field "$1" scope
}

module_config_paths() {
  local name="$1" value p
  value="$(module_field "$name" config_paths)"
  local -a paths=()
  read -r -a paths <<< "$value"
  for p in "${paths[@]}"; do
    [[ -n "$p" ]] || continue
    if [[ "$p" == /* || "$p" == ".." || "$p" == ../* || "$p" == *"/../"* ]]; then
      die "Invalid config_path '$p' in module '$name' (must be relative to \$HOME)."
    fi
    printf '%s\n' "${p%/}"
  done
}

module_notes() {
  module_field "$1" notes
}

module_validate() {
  local name="$1" scope category description p
  module_exists "$name" || die "Unknown module: $name"
  scope="$(module_scope "$name")"
  [[ "$scope" == "scoped" || "$scope" == "shared" ]] || \
    die "Module '$name' has invalid scope '$scope' (expected scoped or shared)."
  category="$(module_field "$name" category)"
  [[ -n "$category" ]] || die "Module '$name' is missing category=."
  description="$(module_field "$name" description)"
  [[ -n "$description" ]] || die "Module '$name' is missing description=."
  while IFS= read -r p; do
    [[ "$p" =~ ^[A-Za-z0-9@._+:-]+$ ]] || die "Module '$name' has an unsafe package name: $p"
  done < <(module_packages "$name"; module_aur_packages "$name")
  # Validates and dies on absolute or parent-relative paths.
  module_config_paths "$name" >/dev/null
}

enabled_modules() {
  local file="$REPO_DIR/enabled.txt"
  [[ -r "$file" ]] || return 0
  awk '
    /^[[:space:]]*#/ { next }
    /^[[:space:]]*$/ { next }
    { gsub(/^[[:space:]]+|[[:space:]]+$/, ""); print }
  ' "$file"
}

is_module_enabled() {
  local name="$1"
  enabled_modules | grep -qxF -- "$name"
}

enable_module() {
  local name="$1" file="$REPO_DIR/enabled.txt" tmp
  module_validate "$name"
  is_module_enabled "$name" && return 0
  tmp="$(mktemp "${file}.XXXXXX")"
  if [[ -f "$file" ]]; then
    cat -- "$file" > "$tmp"
  else
    printf '%s\n' '# Modules enabled by ./install.sh add. One module name per line.' > "$tmp"
  fi
  printf '%s\n' "$name" >> "$tmp"
  mv -- "$tmp" "$file"
  info "Enabled module: $name"
}

disable_module() {
  local name="$1" file="$REPO_DIR/enabled.txt" tmp
  [[ -f "$file" ]] || return 0
  tmp="$(mktemp "${file}.XXXXXX")"
  awk -v m="$name" '
    { gsub(/^[[:space:]]+|[[:space:]]+$/, "") }
    $0 == m { next }
    { print }
  ' "$file" > "$tmp"
  mv -- "$tmp" "$file"
  info "Disabled module: $name"
}

module_summary_line() {
  local name="$1" scope packages
  scope="$(module_scope "$name")"
  packages="$(module_packages "$name" | paste -sd ', ' -)"
  printf '%-12s %-7s %-14s %s\n' "$name" "$scope" "$(module_field "$name" category)" "${packages:-—}"
}

choose_modules() {
  local -a names=() picked=()
  mapfile -t names < <(module_names)
  ((${#names[@]})) || return 0
  if have fzf && [[ -t 0 && -t 1 ]]; then
    mapfile -t picked < <(
      for m in "${names[@]}"; do
        printf '%s\t[%s]\t%s\n' "$m" "$(module_scope "$m")" "$(module_field "$m" description)"
      done | fzf --multi --prompt='Modules> ' --with-nth=1,2,3 | cut -f1
    )
    ((${#picked[@]})) || return 0
  else
    local i choice
    while true; do
      printf '\nAvailable modules:\n' >&2
      i=1
      for m in "${names[@]}"; do
        printf '  %2d) %-12s [%-6s] %s\n' "$i" "$m" "$(module_scope "$m")" "$(module_field "$m" description)" >&2
        ((i++))
      done
      printf '  %2d) Done\n' "$i" >&2
      read -r -p "Select a module number (blank to finish): " choice || break
      [[ -z "$choice" ]] && break
      if [[ "$choice" == "$i" ]]; then
        break
      elif [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice < i )); then
        picked+=("${names[choice-1]}")
      else
        warn "Invalid selection: $choice"
      fi
    done
  fi
  ((${#picked[@]})) || return 0
  printf '%s\n' "${picked[@]}" | awk '!seen[$0]++'
  return 0
}

validate_all_modules() {
  local m
  while IFS= read -r m; do
    module_validate "$m"
  done < <(module_names)
}
