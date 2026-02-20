#!/bin/sh
#~@ Feet Terminal Wrapper
#? Manages foot server with automatic theme detection

#> Get user ID in POSIX-compliant way
USER_ID=$(id -u)
SOCKET="/run/user/${USER_ID}/foot-wayland-0.sock"
THEME_FILE="/tmp/foot-theme-${USER_ID}"

#> Detect current system theme
THEME=$(@detectTheme@)

#> Map to foot's numeric theme (1=dark, 2=light)
if [ "$THEME" = "light" ]; then
  FOOT_THEME=2
else
  FOOT_THEME=1
fi

#> Check if server is running
if pgrep -x "foot" > /dev/null && [ -S "$SOCKET" ]; then
  #> Check if theme changed
  if [ -f "$THEME_FILE" ]; then
    LAST_THEME=$(cat "$THEME_FILE")

    if [ "$LAST_THEME" != "$THEME" ]; then
      echo "Theme changed: $LAST_THEME → $THEME (restarting server...)"
      pkill -x foot
      sleep 0.3
    else
      #> Server running with correct theme, just connect
      exec @footclient@ --server-socket="$SOCKET" "$@"
    fi
  else
    #> No theme file, assume server is correct
    exec @footclient@ --server-socket="$SOCKET" "$@"
  fi
fi

#> Save current theme
echo "$THEME" > "$THEME_FILE"

#> Start server with theme override
@foot@ --server -o main.initial-color-theme="${FOOT_THEME}" > /dev/null 2>&1 &

#> Wait for socket to be ready
i=0
while [ $i -lt 20 ]; do
  if [ -S "$SOCKET" ]; then
    sleep 0.1
    break
  fi
  sleep 0.1
  i=$((i + 1))
done

#> Connect to server
exec @footclient@ --server-socket="$SOCKET" "$@"
