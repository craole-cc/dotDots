#!/bin/sh

set -u

usage() {
  cat <<'EOF'
Usage: reset-flake

Removes deployed template files and transient build directories from the
current project root.
EOF
}

ROOT=${PRJ_ROOT:-$PWD}

while [ "$#" -gt 0 ]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown option: %s\n' "$1" >&2
      exit 1
      ;;
  esac
  shift
done

remove_path() {
  path=$1
  if [ -e "$ROOT/$path" ]; then
    rm -rf "$ROOT/$path"
    printf 'removed %s\n' "$ROOT/$path"
  fi
}

remove_path .cargo/config.toml
if [ -d "$ROOT/.cargo" ] && [ -z "$(find "$ROOT/.cargo" -mindepth 1 -maxdepth 1 2>/dev/null)" ]; then
  rmdir "$ROOT/.cargo" 2>/dev/null || true
fi

remove_path .envrc
remove_path .gitignore
remove_path .markdownlint-cli2.yaml
remove_path markdownlint-cli2.yaml
remove_path .mise.toml
remove_path mise.toml
remove_path .shellcheckrc
remove_path shellcheckrc
remove_path .treefmt.toml
remove_path treefmt.toml
remove_path rust-analyzer.toml
remove_path rust-toolchain.toml
remove_path rustfmt.toml
remove_path .direnv
remove_path target
