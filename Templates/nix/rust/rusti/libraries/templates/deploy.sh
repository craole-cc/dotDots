#!/bin/sh

set -u

print_error() {
  "$CMD_GUM" style --foreground 196 --bold --border normal --border-foreground 196 --padding "0 1" "$1"
}

print_success() {
  "$CMD_GUM" style --foreground 46 --bold "$1"
}

print_warning() {
  "$CMD_GUM" style --foreground 226 --bold "$1"
}

print_info() {
  "$CMD_GUM" style --foreground 250 "$1"
}

usage() {
  cat <<'EOF'
Usage: deploy-templates [--force]

  --force, -f  Overwrite template targets that differ from the source.
  --help,  -h  Show this help text.

By default, changed files are left in place and reported as skipped.
EOF
}

deploy_entry() {
  template_name=$1
  full_source=$2
  preferred_target=$3
  shift 3

  full_preferred=$ROOT/$preferred_target

  if [ ! -f "$full_source" ]; then
    print_error "Template source $full_source is missing." >&2
    return 1
  fi

  mkdir -p "$(dirname "$full_preferred")"

  existing_target=
  existing_count=0

  for target_line in "$@"; do
    full_target=$ROOT/$target_line
    if [ -f "$full_target" ]; then
      existing_count=$((existing_count + 1))
      if [ -z "$existing_target" ] || [ "$full_target" = "$full_preferred" ]; then
        existing_target=$full_target
      fi
    fi
  done

  if [ "$existing_count" -gt 1 ]; then
    print_warning "$template_name: multiple target files detected; using $existing_target." >&2
  fi

  if [ -n "$existing_target" ] && [ "$existing_target" != "$full_preferred" ]; then
    print_info "$template_name: promoting $existing_target -> $full_preferred" >&2
    mv "$existing_target" "$full_preferred"
    chmod u+w "$full_preferred" 2>/dev/null || true
  fi

  if [ ! -f "$full_preferred" ]; then
    print_success "$template_name: deploying $full_preferred" >&2
    cp "$full_source" "$full_preferred"
    chmod u+w "$full_preferred" 2>/dev/null || true
  elif cmp -s "$full_source" "$full_preferred"; then
    print_success "$template_name: already up to date" >&2
  elif [ "$FORCE" -eq 1 ]; then
    print_warning "$template_name: overwriting $full_preferred (--force)" >&2
    cp "$full_source" "$full_preferred"
    chmod u+w "$full_preferred" 2>/dev/null || true
  else
    print_warning "$template_name: local changes detected in $full_preferred; skipping. Re-run with --force to overwrite." >&2
  fi
}

ROOT=${PRJ_ROOT:-$PWD}
FORCE=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    -f|--force)
      FORCE=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      print_error "Unknown option: $1" >&2
      exit 1
      ;;
  esac
  shift
done
