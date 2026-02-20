#!/bin/sh
#~@ Foot Theme Monitor
#? Watches for system theme changes and restarts foot server

THEME_FILE="/tmp/foot-theme-$(id -u)"
CHECK_INTERVAL=2

while true; do
  CURRENT_THEME=$(@detectTheme@)

  if [ -f "$THEME_FILE" ]; then
    LAST_THEME=$(cat "$THEME_FILE")

    if [ "$LAST_THEME" != "$CURRENT_THEME" ]; then
      echo "Theme changed: $LAST_THEME → $CURRENT_THEME"
      echo "Restarting foot server..."

      # Update theme file
      echo "$CURRENT_THEME" > "$THEME_FILE"

      # Kill and restart foot server
      pkill -x foot
      sleep 0.5

      # Start new server with correct theme
      if [ "$CURRENT_THEME" = "light" ]; then
        @foot@ --server -o main.initial-color-theme=2 > /dev/null 2>&1 &
      else
        @foot@ --server -o main.initial-color-theme=1 > /dev/null 2>&1 &
      fi
    fi
  fi

  sleep "$CHECK_INTERVAL"
done
