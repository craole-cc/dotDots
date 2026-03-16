#!/bin/sh
# shellcheck enable=all
set -eu

#~@ Injected by Nix via replaceVarsWith
CMD_SD="@cmdSd@"
CMD_DCONF="@cmdDconf@"
CMD_NOTIFY="@cmdNotify@"
CMD_WALLMAN="@cmdWallman@"
CFG_POLARITY="@cfgPolarity@"
CFG_API="@cfgApi@"

#~@ State
STATE_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/theme-mode.state"

#~@ Skip if already in requested mode
if [ -f "$STATE_FILE" ] && [ "$(cat "$STATE_FILE")" = "$CFG_POLARITY" ]; then
	printf 'Already in %s mode, skipping...\n' "$CFG_POLARITY"
	exit 0
fi

printf '=== Switching to %s mode ===\n' "$CFG_POLARITY"

#> 1. Update polarity in user API config
printf '1. Updating user API...\n'
"$CMD_SD" 'polarity = "(dark|light)"' "polarity = \"$CFG_POLARITY\"" "$CFG_API" || {
	printf 'Warning: Failed to update API\n'
}

#> 2. Set freedesktop portal via dconf (Hyprland-compatible)
#?  xdg-desktop-portal-hyprland does not support Settings.Write via dbus
#?  dconf directly writes to the same key without requiring GNOME schemas
printf '2. Setting portal color-scheme...\n'
"$CMD_DCONF" write /org/gnome/desktop/interface/color-scheme \
	"'prefer-$CFG_POLARITY'" 2>/dev/null || {
	printf 'Warning: dconf write failed\n'
}

#> 3. GTK theme (gsettings if available, dconf fallback)
#?  adw-gtk3 light variant has no suffix; dark variant is "adw-gtk3-dark"
printf '3. Setting GTK theme...\n'
case "$CFG_POLARITY" in
dark) gtk_theme="adw-gtk3-dark" ;;
light) gtk_theme="adw-gtk3" ;;
esac
if command -v gsettings >/dev/null 2>&1; then
	gsettings set org.gnome.desktop.interface color-scheme \
		"prefer-$CFG_POLARITY" 2>/dev/null || true
	gsettings set org.gnome.desktop.interface gtk-theme \
		"$gtk_theme" 2>/dev/null || true
else
	"$CMD_DCONF" write /org/gnome/desktop/interface/gtk-theme \
		"'$gtk_theme'" 2>/dev/null || true
fi

#> 4. Update wallpapers
printf '4. Updating wallpapers...\n'
"$CMD_WALLMAN" set --polarity "$CFG_POLARITY" 2>/dev/null || {
	printf 'Warning: Wallpaper update had issues\n'
}

#> 5. Toggle foot theme via signal (no restart, no kill!)
printf '5. Toggling foot color theme...\n'
FOOT_PID=$(pgrep -x foot 2>/dev/null || printf "")
if [ -n "$FOOT_PID" ]; then
	case "$CFG_POLARITY" in
	dark) kill -USR1 "$FOOT_PID" 2>/dev/null || true ;;
	light) kill -USR2 "$FOOT_PID" 2>/dev/null || true ;;
	esac
	printf 'Sent %s signal to foot (PID %s)\n' "$CFG_POLARITY" "$FOOT_PID"
else
	printf 'Warning: foot not running\n'
fi

#> 6. Notify user
printf '6. Notifying...\n'
"$CMD_NOTIFY" \
	--urgency=low \
	--expire-time=2000 \
	"Theme" "Switched to $CFG_POLARITY mode" 2>/dev/null || true

#> Update state file
mkdir -p "$(dirname "$STATE_FILE")"
printf '%s\n' "$CFG_POLARITY" >"$STATE_FILE"

printf '=== Done ===\n'
