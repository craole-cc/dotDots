#!/bin/sh
main() {
  set_defaults
  parse_arguments "$@"
  validate_env
  execute_process
}

set_defaults() {
  #@ Define modes of operation
  debug=0
  strict=1
  set_modes

  #@ Define script information
  SCR_NAME="$(basename "$0")"

  #@ Define commands
  CMD_NIX="$(command -v nix 2> /dev/null)"
  CMD_REALPATH="$(command -v realpath 2> /dev/null)"
  CMD_READLINK="$(command -v readlink 2> /dev/null)"

  #@ Attempt to retrieve the path to the flake
  GIT_DIR=$(git rev-parse --show-toplevel 2> /dev/null)
  TARGET_FLAKE="${FLAKE:-"${PRJ_ROOT:-"${GIT_DIR}"}"}"
}

set_modes() {
  case "${strict:-}" in
    '' | off | false | 0) ;;
    on | true | 1) set -eu ;;
    *) ;;
  esac

  case "${debug:-}" in
    '' | off | false | 0) debug=0 ;;
    on | true | 1) debug=1 ;;
    trace) debug=2 ;;
    *)
      if ! [ "${debug}" -eq "${debug}" ] 2> /dev/null; then
        printf "❌ Unknown debug value: %s" "${debug}"
        exit 1
      fi
      ;;
  esac

  if [ "${debug:-}" -gt 1 ]; then
    set -x #? Not POSIX-compliant
  fi
}

pout_debug() {
  if [ "${debug:-}" -ge 1 ]; then
    printf "[DEBUG] %s\n" "$*"
  fi
}

validate_env() {
  pout_debug "Debug mode enabled"
  pout_debug "Strict mode:" "${strict}"
  pout_debug "SCR_NAME:" "${SCR_NAME}"
  pout_debug "CMD_NIX:" "${CMD_NIX}"
  pout_debug "CMD_REALPATH:" "${CMD_REALPATH}"
  pout_debug "GIT_DIR:" "${GIT_DIR}"
  pout_debug "TARGET_FLAKE:" "${TARGET_FLAKE}"

  if [ -z "${CMD_NIX}" ]; then
    printf "❌ Nix not found - install from https://nixos.org/download"
    exit 1
  fi

  if [ -z "${TARGET_FLAKE:-}" ]; then
    printf "❌ No flake specified"
    exit 1
  fi
  pout_debug "Flake defined as" "${TARGET_FLAKE}"

  if [ ! -d "${TARGET_FLAKE}" ]; then
    printf "❌ Flake not found"
    exit 1
  fi
  pout_debug "Flake exists and is a directory:" "${TARGET_FLAKE}"

  if [ -n "${CMD_REALPATH}" ]; then
    TARGET_FLAKE="$("${CMD_REALPATH}" "${TARGET_FLAKE}")"
  elif [ -n "${CMD_READLINK}" ]; then
    TARGET_FLAKE="$("${CMD_READLINK}" -f "${TARGET_FLAKE}")"
  else
    printf "❌ Neither realpath nor readlink found; cannot resolve Flake path.\n Install 'coreutils' using you package manager or nix-shell -p coreutils.\n"
    exit 1
  fi
  pout_debug "Resolved Flake:" "${TARGET_FLAKE}"
}

parse_arguments() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      -h | --help | help | "/?")
        show_help
        exit 0
        ;;
      -d | --debug | debug | trace | "/d")
        debug=1
        ;;
      -f | --flake | flake | "/f")
        [ -n "${2}" ] && SPECIFIED_FLAKE="$2" && shift
        ;;
      *) SPECIFIED_FLAKE="$1" ;;
    esac
    shift
  done

  if [ -n "${SPECIFIED_FLAKE:-}" ]; then
    TARGET_FLAKE="${SPECIFIED_FLAKE}"
  fi
}

execute_process() {
  "${CMD_NIX}" repl --expr "builtins.getFlake \"${TARGET_FLAKE}\""
}

show_help() {
  cat << EOF
Usage: ${SCR_NAME} [OPTIONS] [PATH_TO_FLAKE]

Options:
  -h, /?, --help, help        Display this help and exit
  -d, /d, --debug, debug      Enable debug mode
  -f, /f, --flake, flake      Specify the flake to load

Description:
  Loads the system flake if available, or a specified flake.

Examples:
  ${SCR_NAME}
  ${SCR_NAME} --flake ${TARGET_FLAKE:-${PWD}}
  ${SCR_NAME} ${TARGET_FLAKE:-${PWD}}
EOF
}

main "${@:-}"
