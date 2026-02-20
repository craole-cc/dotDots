#!/bin/sh
set -eu

#> Configuration and Commands (injected by Nix)
CMD_SD="@cmdSd@"
CMD_DBUS="@cmdDbus@"
CMD_DCONF="@cmdDconf@"
CMD_NOTIFY="@cmdNotify@"
CMD_WALLMAN="@cmdWallman@"
CFG_POLARITY="@cfgPolarity@"
CFG_API="@cfgApi@"

# State file to track current mode
STATE_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/theme-mode.state"

case "$CFG_POLARITY" in "dark") PORTAL_MODE="1" ;; *) PORTAL_MODE="2" ;; esac

# Check if we're already in the requested mode
if [ -f "$STATE_FILE" ]; then
  CURRENT_MODE=$(cat "$STATE_FILE")
  if [ "$CURRENT_MODE" = "$CFG_POLARITY" ]; then
    printf 'Already in %s mode, skipping...\n' "$CFG_POLARITY"
    exit 0
  fi
fi

printf '=== Switching to %s mode ===\n' "$CFG_POLARITY"

#> 1. Update theme polarity in user configuration
printf '1. Updating user API...\n'
"$CMD_SD" 'polarity = "(dark|light)"' "polarity = \"$CFG_POLARITY\"" "$CFG_API" || {
  printf 'Warning: Failed to update API\n'
}

#> 2. Update freedesktop portal (primary method)
printf '2. Setting freedesktop portal...\n'
"$CMD_DBUS" --session --dest=org.freedesktop.portal.Desktop \
  --type=method_call /org/freedesktop/portal/desktop \
  org.freedesktop.portal.Settings.Write \
  string:'org.freedesktop.appearance' string:'color-scheme' \
  variant:uint32:"$PORTAL_MODE" 2>&1 | grep -v "GDBus.Error" || true

#> 3. Use gsettings instead of dconf (works on your system)
printf '3. Setting GNOME/GTK preferences...\n'
if command -v gsettings > /dev/null 2>&1; then
  # gsettings set org.gnome.desktop.interface color-scheme "prefer-$CFG_POLARITY" 2>/dev/null || true
  # Don't change gtk-theme if you're using adw-gtk3-dark
  gsettings set org.gnome.desktop.interface gtk-theme "adw-gtk3-$CFG_POLARITY" 2> /dev/null || true
else
  # Fallback to dconf
  "$CMD_DCONF" write /org/gnome/desktop/interface/color-scheme "'prefer-$CFG_POLARITY'" 2> /dev/null || true
fi

#> 4. Set XSettings (for older GTK apps)
printf '4. Setting XSettings...\n'
if command -v xfconf-query > /dev/null 2>&1; then
  xfconf-query -c xsettings -p /Net/ThemeName -s "Adwaita-$CFG_POLARITY" 2> /dev/null || true
fi

#> 5. Update wallpapers
printf '5. Updating wallpapers...\n'
"$CMD_WALLMAN" set --polarity "$CFG_POLARITY" 2>&1 | grep -v "Error\|Warning" || {
  printf 'Warning: Wallpaper update had issues\n'
}

#> 6. Send notification (only on actual change)
printf '6. Sending notification...\n'
"$CMD_NOTIFY" "Theme Switched" "Switched to $CFG_POLARITY mode" -t 2000 2> /dev/null || {
  printf 'Warning: Failed to send notification\n'
}

# Update state file
mkdir -p "$(dirname "$STATE_FILE")"
printf '%s\n' "$CFG_POLARITY" > "$STATE_FILE"

printf '=== Done ===\n'
