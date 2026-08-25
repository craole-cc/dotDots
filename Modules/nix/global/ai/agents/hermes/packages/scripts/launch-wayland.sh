#!/bin/sh
# shellcheck shell=sh
set -eu

if [ -z "${WAYLAND_DISPLAY:-}" ]; then
  if [ -z "${XDG_RUNTIME_DIR:-}" ] || [ ! -d "$XDG_RUNTIME_DIR" ]; then
    printf '%s\n' "Cannot launch graphical Hermes: WAYLAND_DISPLAY is unset and XDG_RUNTIME_DIR is not an existing directory." >&2
    exit 1
  fi

  wayland_socket=""
  socket_count=0
  for candidate in "$XDG_RUNTIME_DIR"/wayland-*; do
    [ -S "$candidate" ] || continue
    socket_count=$((socket_count + 1))
    wayland_socket="$candidate"
  done

  case "$socket_count" in
    0)
      printf '%s\n' "Cannot launch graphical Hermes: WAYLAND_DISPLAY is unset and no Wayland sockets were found in XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR." >&2
      exit 1
      ;;
    1)
      WAYLAND_DISPLAY=${wayland_socket##*/}
      export WAYLAND_DISPLAY
      ;;
    *)
      printf '%s\n' "Cannot launch graphical Hermes: WAYLAND_DISPLAY is unset and multiple Wayland sockets were found in XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR." >&2
      exit 1
      ;;
  esac
fi

exec "$@"
