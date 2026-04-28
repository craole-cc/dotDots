#!/bin/sh

set -eu

main() {
  if [ "$#" -eq 0 ]; then
    mission_list
    exit 0
  fi

  case "$1" in
    help|list|ls)
      mission_list
      ;;
    *)
      mission_run "$@"
      ;;
  esac
}

main "$@"
