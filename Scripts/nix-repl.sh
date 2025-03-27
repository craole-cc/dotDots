#!/bin/sh

#@ Validate required environment variables
CMD_NIX="$(command -v nix)"
CMD_READLINK="$(command -v readlink)"
CMD_SED="$(command -v sed)"
if [ -z "${CMD_READLINK}" ] || [ -z "${CMD_SED}" ]; then
  printf "[Error]: repl.sh requires CMD_READLINK and CMD_SED to be set\n" >&2
  exit 1
fi

show_help() {
  printf "\e[4mUsage\e[0m:\n"
  printf "repl - Loads system flake if available\n"
  printf "repl /path/to/flake.nix - Loads specified flake\n"
}

# Main script logic
case "$1" in
"-h" | "--help" | "help")
  show_help
  exit 0
  ;;
*)
  if [ -n "${CMD_NIX}" ]; then
    nix repl "${@:-"${FLAKE:-"${PRJ_ROOT}"}"}"
  else
    :
  fi
  ;;
esac
