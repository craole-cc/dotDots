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

#> Update theme mode in user configuration
"$CMD_SD" 'polarity = "(dark|light)"' "polarity = \"$CFG_POLARITY\"" "$CFG_API"

#> Update the freedesktop portal setting
"$CMD_DBUS" --session --dest=org.freedesktop.portal.Desktop \
	--type=method_call /org/freedesktop/portal/desktop \
	org.freedesktop.portal.Settings.ReadOne \
	string:'org.freedesktop.appearance' string:'color-scheme' \
	uint32:"$PORTAL_MODE" 2>/dev/null || true

#> Update GTK/Qt theming preference
"$CMD_DCONF" write /org/gnome/desktop/interface/color-scheme "'prefer-$CFG_POLARITY'" || true

#> Update wallpapers for all monitors using wallman
"$CMD_WALLMAN" set --polarity "$CFG_POLARITY" || true

#> Notify
"$CMD_NOTIFY" "Theme Switched" "Switched to $CFG_POLARITY mode" -t 2000 || true
