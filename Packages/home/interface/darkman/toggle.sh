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

case "$CFG_POLARITY" in
"dark")
	PORTAL_MODE="1"
	;;
*)
	PORTAL_MODE="2"
	;;
esac

echo "=== Switching to $CFG_POLARITY mode ==="

#> 1. Update theme polarity in user configuration
echo "1. Updating user API..."
"$CMD_SD" 'polarity = "(dark|light)"' "polarity = \"$CFG_POLARITY\"" "$CFG_API" || {
	echo "Warning: Failed to update API"
}

#> 2. Update freedesktop portal (primary method)
echo "2. Setting freedesktop portal..."
"$CMD_DBUS" --session --dest=org.freedesktop.portal.Desktop \
	--type=method_call /org/freedesktop/portal/desktop \
	org.freedesktop.portal.Settings.Write \
	string:'org.freedesktop.appearance' string:'color-scheme' \
	variant:uint32:"$PORTAL_MODE" 2>&1 | grep -v "GDBus.Error" || true

#> 3. Use gsettings instead of dconf (works on your system)
echo "3. Setting GNOME/GTK preferences..."
if command -v gsettings >/dev/null 2>&1; then
	gsettings set org.gnome.desktop.interface color-scheme "prefer-$CFG_POLARITY" 2>/dev/null || true
	# Don't change gtk-theme if you're using adw-gtk3-dark
	# gsettings set org.gnome.desktop.interface gtk-theme "adw-gtk3-$CFG_POLARITY" 2>/dev/null || true
else
	# Fallback to dconf
	"$CMD_DCONF" write /org/gnome/desktop/interface/color-scheme "'prefer-$CFG_POLARITY'" 2>/dev/null || true
fi

#> 4. Set XSettings (for older GTK apps)
echo "4. Setting XSettings..."
if command -v xfconf-query >/dev/null 2>&1; then
	xfconf-query -c xsettings -p /Net/ThemeName -s "Adwaita-$CFG_POLARITY" 2>/dev/null || true
fi

#> 5. Update wallpapers
echo "5. Updating wallpapers..."
"$CMD_WALLMAN" set --polarity "$CFG_POLARITY" 2>&1 | grep -v "Error\|Warning" || {
	echo "Warning: Wallpaper update had issues"
}

#> 6. Send notification
echo "6. Sending notification..."
"$CMD_NOTIFY" "Theme Switched" "Switched to $CFG_POLARITY mode" -t 2000 2>/dev/null || {
	echo "Warning: Failed to send notification"
}

echo "=== Done ==="
