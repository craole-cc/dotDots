#!/bin/sh

case "$1" in
  "-h" | "--help" | "help")
    printf "%b\n\e[4mUsage\e[0m:\n" \
      "repl - Loads system flake if available.\n" \
      "repl /path/to/flake.nix - Loads specified flake.\n"
    ;;
  *)
    if [ -z "$1" ]; then
      nix repl "${FLAKE}"
    else
      if [ -n "${CMD_READLINK}" ] && [ -n "${CMD_SED}" ]; then
        flake_path="$("${CMD_READLINK}" -f "$1")"
        flake_path_flake="$(printf "%s" "${flake_path}" | "${CMD_SED}" 's|/flake.nix||')"

        nix repl --argstr flakePath "${flake_path_flake}"
      else
        printf "[Error]: repl.sh is missing dependencies\n" >&2
        exit 1
      fi
    fi
    ;;
esac
