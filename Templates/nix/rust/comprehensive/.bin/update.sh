#!/bin/sh
# shellcheck enable=all

find_cmd() { command -v "$1" 2>/dev/null || true; }
if [ -z "${CMD_CARGO:-}" ]; then CMD_CARGO="$(find_cmd cargo)"; fi
if [ -z "${CMD_DIRENV:-}" ]; then CMD_DIRENV="$(find_cmd direnv)"; fi
if [ -z "${CMD_GIT:-}" ]; then CMD_GIT="$(find_cmd git)"; fi
if [ -z "${CMD_MISE:-}" ]; then CMD_MISE="$(find_cmd mise)"; fi
if [ -z "${CMD_NIX:-}" ]; then CMD_NIX="$(find_cmd nix)"; fi

is_true() {
  case "$(printf '%s' "${1:-}" | tr '[:upper:]' '[:lower:]')" in
  1 | yes | true | on | enable*) return 0 ;;
  *) return 1 ;;
  esac
}

usage() {
  printf 'Usage: update [OPTIONS]\n'
  printf '\n'
  printf 'Options:\n'
  printf '  --rust, --cargo  Also run cargo update\n'
  printf '  --mise           Also run mise self-update\n'
  printf '  --no-flake       Skip nix flake update\n'
  printf '  --help           Show this help\n'
}

flake=1
cargo=0
mise=0

for arg in "$@"; do
  case "${arg}" in
  --rust | --cargo) cargo=1 ;;
  --mise) mise=1 ;;
  --no-flake) flake=0 ;;
  --help)
    usage
    exit 0
    ;;
  *) ;;
  esac
done

if is_true "${flake}" && [ -n "${CMD_NIX}" ]; then
  "${CMD_NIX}" flake update 2>/dev/null
fi

if is_true "${cargo}" && [ -n "${CMD_CARGO}" ]; then
  "${CMD_CARGO}" update
  "${CMD_CARGO}" reload
fi

if is_true "${mise}" && [ -n "${CMD_MISE}" ]; then
  "${CMD_MISE}" self-update
fi

if [ -n "${CMD_GIT}" ]; then
  "${CMD_GIT}" add --all

  case "$("${CMD_GIT}" status --porcelain)" in
  ?*)
    "${CMD_GIT}" commit --message "update"
    "${CMD_GIT}" push
    ;;
  *) ;;
  esac
fi

if [ -n "${CMD_DIRENV}" ]; then
  "${CMD_DIRENV}" reload
fi
