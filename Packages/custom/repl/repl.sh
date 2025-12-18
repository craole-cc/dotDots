#!/bin/sh

# Validate required environment variables
if [ -z "${CMD_READLINK}" ] || [ -z "${CMD_SED}" ]; then
  printf "[Error]: repl.sh requires CMD_READLINK and CMD_SED to be set\n" >&2
  exit 1
fi

# Help function
show_help() {
  printf "\e[4mUsage\e[0m:\n"
  printf "repl - Loads system flake if available\n"
  printf "repl /path/to/flake.nix - Loads specified flake\n"
}

flake_path_dir="${1:-"${FLAKE:-"${PRJ_ROOT:-"$(pwd -P)"}"}"}"

# Main script logic
case "$1" in
  "-h" | "--help" | "help")
    show_help
    exit 0
    ;;
  *)
    if [ -z "$1" ]; then
      #{ Use the detected flake path
      nix repl "${flake_path_dir}"
    else
      #{ Validate and process provided path
      flake_path="$("${CMD_READLINK}" -f "$1")"
      flake_path_dir="$(printf "%s" "${flake_path}" | "${CMD_SED}" 's|/flake.nix||')"

      if [ -d "${flake_path_dir}" ]; then
        nix repl --argstr flakePath "${flake_path_dir}"
      else
        printf "[Error]: Invalid flake path: %s\n" "${flake_path_dir}" >&2
        exit 1
      fi
    fi
    ;;
esac
