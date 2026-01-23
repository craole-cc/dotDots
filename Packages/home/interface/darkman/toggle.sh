set -euo pipefail

#> Tools (injected by Nix)
CMD_SD="@sd@"
CMD_DBUS="@dbus@"
CMD_DCONF="@dconf@"
CMD_NOTIFY="@notify@"
CMD_WALLMAN="@wallman@"
MODE="@mode@"
API="@api@"
PORTAL="@portalMode@"

#> Update theme mode in user configuration
${CMD_SD} 'current = "(dark|light)"' 'current = "${mode}"' "${API}"

#> Update the freedesktop portal setting
${CMD_DBUS} --session --dest=org.freedesktop.portal.Desktop \
	--type=method_call /org/freedesktop/portal/desktop \
	org.freedesktop.portal.Settings.ReadOne \
	string:'org.freedesktop.appearance' string:'color-scheme' \
	uint32:${PORTAL} 2>/dev/null || true

#> Update GTK/Qt theming preference
${CMD_DCONF} write /org/gnome/desktop/interface/color-scheme "'prefer-${MODE}'" || true

#> Update wallpapers for all monitors using wallman
${CMD_WALLMAN} set --polarity ${MODE} || true

#> Notify
${CMD_NOTIFY} "Theme Switched" "Switched to ${MODE} mode" -t 2000 || true
