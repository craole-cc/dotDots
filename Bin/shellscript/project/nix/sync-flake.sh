#!/bin/sh
# shellcheck enable=all

main() {
  set_defaults
  parse_arguments "$@"
  update_flake
}

set_defaults() {
  #~@ Enable strict mode
  set -eu

  #~@ Check if flakes enabled
  msg="Flake Update"
  flakes="$(nix flake --help 2>/dev/null)"
  delimiter=" "
  args=""
}

parse_arguments() {

  #~@ Parse arguments
  while [ $# -gt 0 ]; do
    case "${1}" in
    -a | --arg*)
      args="${args}${args:+${delimiter}}${2}"
      shift
      ;;
    *)
      args="${args}${args:+${delimiter}}${1}"
      ;;
    esac
    shift
  done
}

update_flake() {
  if [ -z "${flakes}" ]; then
    printf "Nix flake doesn't seem to be available\n"
    return 1
  else
    eval nix flake update "${args}" --commit-lock-file
    # eval nix flake archive
    return 0
  fi
}

main "$@"
