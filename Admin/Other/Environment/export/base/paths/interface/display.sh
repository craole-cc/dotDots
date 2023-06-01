#!/bin/sh
# shellcheck disable=SC1091

# |> Graphical Server <|
start_X11() {
  . "${DOTS_ENV_DESKTOPS}/X11"
  [ "$RC_xinit" ] && bat "$RC_xinit"
}

StartWayland() {
  if [ -z "$DISPLAY" ] && [ "$(tty)" = /dev/tty1 ]; then
    if [ "$RC_xinit" ]; then
      startx "$RC_xinit"
      echo "X"
    else
      startx
    fi
  fi
}
