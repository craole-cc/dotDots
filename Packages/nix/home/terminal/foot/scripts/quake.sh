#!/bin/sh
#~@ Feet Quake Mode
#? Toggle-able dropdown terminal (quake-style)

SOCKET="/run/user/$(id -u)/foot-wayland-0.sock"
QUAKE_ID="foot-quake"

#> Check if quake terminal is already running
if pgrep -f "$QUAKE_ID" > /dev/null; then
  #> Toggle visibility (hide if visible, show if hidden)
  if command -v hyprctl > /dev/null 2>&1; then
    # Hyprland
    hyprctl dispatch togglespecialworkspace quake
  elif command -v swaymsg > /dev/null 2>&1; then
    # Sway
    swaymsg '[app_id="'$QUAKE_ID'"]' scratchpad show
  else
    # Fallback: just kill it
    pkill -f "$QUAKE_ID"
  fi
else
  #> Launch quake terminal
  if command -v hyprctl > /dev/null 2>&1; then
    # Hyprland: launch in special workspace
    @footclient@ \
      --app-id="$QUAKE_ID" \
      --window-size-chars=200x50 \
      --server-socket="$SOCKET" &
    sleep 0.1
    hyprctl dispatch movetoworkspacesilent special:quake,"$QUAKE_ID"
    hyprctl dispatch togglespecialworkspace quake
  elif command -v swaymsg > /dev/null 2>&1; then
    # Sway: launch in scratchpad
    @footclient@ \
      --app-id="$QUAKE_ID" \
      --window-size-chars=200x50 \
      --server-socket="$SOCKET" &
    sleep 0.2
    swaymsg '[app_id="'$QUAKE_ID'"]' move scratchpad
    swaymsg '[app_id="'$QUAKE_ID'"]' scratchpad show
  else
    # Generic Wayland: just launch maximized at top
    @footclient@ \
      --app-id="$QUAKE_ID" \
      --window-size-pixels=1920x600 \
      --server-socket="$SOCKET" &
  fi
fi
