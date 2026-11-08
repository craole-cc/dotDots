#!/usr/bin/env bash
set -euo pipefail

target_directory=$1
legacy_directory=$2
dry_run=${3:-}
backup_extension=${HOME_MANAGER_BACKUP_EXT:-hm-backup}

for mapping in 'yazi.toml:config.toml' 'keymap.toml:keymap.toml'; do
  target="$target_directory/${mapping%%:*}"
  legacy="$legacy_directory/${mapping#*:}"
  [ -L "$target" ] || continue
  [ "$(readlink -- "$target")" = "$legacy" ] || continue

  backup="$target.$backup_extension"
  index=0
  while [ -e "$backup" ] || [ -L "$backup" ]; do
    index=$((index + 1))
    backup="$target.$backup_extension.$index"
  done

  printf 'Backing up legacy Yazi link %s to %s\n' "$target" "$backup"
  if [ -z "$dry_run" ]; then
    mv -T -- "$target" "$backup"
  fi
done
