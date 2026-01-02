#!/bin/sh
#~@ Feet - Smart Foot Terminal Wrapper
#? POSIX-compliant theme detection and terminal launcher
#? Location: $DOTS/Bin/shellscript/packages/wrappers/feet.sh

set -e

USER_ID=$(id -u)
THEME_FILE="/tmp/foot-theme-$USER_ID"
SOCKET="/run/user/$USER_ID/foot-wayland-0.sock"

#> Helper to check if command exists
has_cmd() { command -v "$1" >/dev/null 2>&1; }

#> Theme Detection Function
detect_theme() {
	#| 1. Check KDE Plasma
	if [ -f "$HOME/.config/kdeglobals" ]; then
		KDE_SCHEME=$(grep "^ColorScheme=" "$HOME/.config/kdeglobals" | head -1 | cut -d= -f2)
		case "$KDE_SCHEME" in
		*[Dd]ark*)
			printf "dark"
			return 0
			;;
		*[Ll]ight*)
			printf "light"
			return 0
			;;
		*)
			INACTIVE_COLOR=$(grep -A5 "^\[ColorEffects:Inactive\]" "$HOME/.config/kdeglobals" | grep "^Color=" | cut -d= -f2)
			if [ -n "$INACTIVE_COLOR" ]; then
				R=$(printf '%s' "$INACTIVE_COLOR" | cut -d, -f1)
				if [ "$R" -gt 100 ] 2>/dev/null; then
					printf "light"
					return 0
				else
					printf "dark"
					return 0
				fi
			fi
			;;
		esac
	fi

	#| 2. Check freedesktop portal
	if has_cmd dbus-send; then
		THEME=$(dbus-send --session --print-reply=literal --reply-timeout=100 \
			--dest=org.freedesktop.portal.Desktop \
			/org/freedesktop/portal/desktop \
			org.freedesktop.portal.Settings.Read \
			string:'org.freedesktop.appearance' string:'color-scheme' 2>/dev/null |
			grep -oE 'uint32 [0-9]+' | awk '{print $2}')

		case "$THEME" in
		1)
			printf "dark"
			return 0
			;;
		2)
			printf "light"
			return 0
			;;
		esac
	fi

	#| 3. Check GNOME settings
	if has_cmd gsettings; then
		SCHEME=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null || printf "")
		case "$SCHEME" in
		*dark* | *prefer-dark*)
			printf "dark"
			return 0
			;;
		*light* | *prefer-light*)
			printf "light"
			return 0
			;;
		esac
	fi

	#| 4. Check GTK theme
	for conf in "$HOME/.config/gtk-4.0/settings.ini" "$HOME/.config/gtk-3.0/settings.ini"; do
		if [ -f "$conf" ]; then
			GTK_THEME=$(grep "^gtk-theme-name" "$conf" | cut -d= -f2 | tr -d ' "')
			case "$GTK_THEME" in
			*[Dd]ark*)
				printf "dark"
				return 0
				;;
			*[Ll]ight*)
				printf "light"
				return 0
				;;
			esac
		fi
	done

	#| 5. Check environment variables
	case "${GTK_THEME:-}:${QT_STYLE_OVERRIDE:-}" in
	*[Dd]ark*)
		printf "dark"
		return 0
		;;
	*[Ll]ight*)
		printf "light"
		return 0
		;;
	esac

	#| 6. Time-based fallback
	HOUR=$(date +%H)
	if [ "$HOUR" -ge 6 ] && [ "$HOUR" -lt 18 ]; then
		printf "light"
	else
		printf "dark"
	fi
}

#> Theme Monitor Mode
monitor_mode() {
	# Enable debug mode if DEBUG env var is set
	DEBUG="${FOOT_THEME_DEBUG:-0}"

	printf "Starting foot theme monitor...\n" >&2

	# Initialize theme file
	CURRENT_THEME=$(detect_theme)
	printf '%s' "$CURRENT_THEME" >"$THEME_FILE"
	printf "Initial theme: %s\n" "$CURRENT_THEME" >&2

	while true; do
		sleep 2
		NEW_THEME=$(detect_theme)

		if [ "$DEBUG" = "1" ]; then
			printf "[DEBUG] Checked theme: %s\n" "$NEW_THEME" >&2
		fi

		if [ -f "$THEME_FILE" ]; then
			LAST_THEME=$(cat "$THEME_FILE")

			if [ "$LAST_THEME" != "$NEW_THEME" ]; then
				printf "Theme changed: %s → %s\n" "$LAST_THEME" "$NEW_THEME" >&2
				printf '%s' "$NEW_THEME" >"$THEME_FILE"
				printf "Press F12 in terminals to toggle theme, or close and reopen them.\n" >&2
			fi
		fi
	done
}

#> Quake Mode
quake_mode() {
	QUAKE_ID="foot-quake"

	# Check if quake terminal is running
	if pgrep -f "$QUAKE_ID" >/dev/null; then
		# Just toggle - kill if running
		pkill -f "$QUAKE_ID"
		exit 0
	fi

	# Ensure server is running first
	if ! pgrep -x foot >/dev/null 2>&1 || [ ! -S "$SOCKET" ]; then
		# Start server with current theme
		THEME=$(detect_theme)
		if [ "$THEME" = "light" ]; then
			FOOT_THEME=2
		else
			FOOT_THEME=1
		fi

		printf '%s' "$THEME" >"$THEME_FILE"
		rm -f "$SOCKET"
		foot --server -o main.initial-color-theme="$FOOT_THEME" >/dev/null 2>&1 &

		# Wait for server
		i=0
		while [ $i -lt 50 ]; do
			if [ -S "$SOCKET" ]; then
				sleep 0.3
				break
			fi
			sleep 0.1
			i=$((i + 1))
		done

		if [ ! -S "$SOCKET" ]; then
			printf "Error: Failed to start foot server for quake mode\n" >&2
			exit 1
		fi
	fi

	# Launch quake terminal
	# Try WM-specific methods first, fall back to simple approach
	if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ] && has_cmd hyprctl; then
		# Hyprland detected and running
		footclient \
			--app-id="$QUAKE_ID" \
			--window-size-chars=200x50 \
			--server-socket="$SOCKET" >/dev/null 2>&1 &
		sleep 0.1
		hyprctl dispatch movetoworkspacesilent special:quake,"$QUAKE_ID" 2>/dev/null
		hyprctl dispatch togglespecialworkspace quake 2>/dev/null
	elif has_cmd swaymsg && pgrep -x sway >/dev/null 2>&1; then
		# Sway detected and running
		footclient \
			--app-id="$QUAKE_ID" \
			--window-size-chars=200x50 \
			--server-socket="$SOCKET" >/dev/null 2>&1 &
		sleep 0.2
		swaymsg "[app_id=\"$QUAKE_ID\"]" move scratchpad 2>/dev/null
		swaymsg "[app_id=\"$QUAKE_ID\"]" scratchpad show 2>/dev/null
	else
		# Generic approach - works on any Wayland compositor
		# Launch at top of screen with specific size
		footclient \
			--app-id="$QUAKE_ID" \
			--window-size-chars=240x40 \
			--server-socket="$SOCKET" >/dev/null 2>&1 &
	fi
}

#> Launch Terminal Mode (Default)
launch_terminal() {
	THEME=$(detect_theme)

	# Map theme to foot's numeric format
	if [ "$THEME" = "light" ]; then
		FOOT_THEME=2
	else
		FOOT_THEME=1
	fi

	# Always clean up stale socket
	if [ -S "$SOCKET" ] && ! pgrep -x foot >/dev/null 2>&1; then
		rm -f "$SOCKET"
	fi

	# Simple check: is server running?
	if pgrep -x foot >/dev/null 2>&1 && [ -S "$SOCKET" ]; then
		# Server running, just connect
		exec footclient --server-socket="$SOCKET" "$@"
	fi

	# No server - start one with current theme
	printf '%s' "$THEME" >"$THEME_FILE"

	# Clean socket just in case
	rm -f "$SOCKET"

	# Start server
	foot --server -o main.initial-color-theme="$FOOT_THEME" >/dev/null 2>&1 &

	# Wait for socket with proper timing
	i=0
	while [ $i -lt 50 ]; do
		if [ -S "$SOCKET" ]; then
			# Found socket, wait a bit more for server initialization
			sleep 0.3
			break
		fi
		sleep 0.1
		i=$((i + 1))
	done

	# Final check
	if [ ! -S "$SOCKET" ]; then
		printf "Error: Failed to start foot server\n" >&2
		exit 1
	fi

	# Connect
	exec footclient --server-socket="$SOCKET" "$@"
}

#> Main execution
case "${1:-}" in
--monitor | -m)
	monitor_mode
	;;
--quake | -q)
	shift
	quake_mode
	;;
--detect | -d)
	detect_theme
	printf "\n"
	;;
--help | -h)
	cat <<EOF
Feet - Smart Foot Terminal Wrapper

USAGE:
  feet [OPTIONS] [ARGS...]

OPTIONS:
  (no args)        Launch terminal with automatic theme detection
  --monitor, -m    Run theme monitoring service (watches for system changes)
  --quake, -q      Toggle quake-style dropdown terminal
  --detect, -d     Detect and print current theme (dark/light)
  --help, -h       Show this help message

EXAMPLES:
  feet                    # Launch terminal
  feet --monitor          # Start theme monitor daemon
  feet --detect           # Check current theme
  feet -e nvim file.txt   # Launch terminal running nvim

NOTES:
  - Requires foot terminal emulator installed
  - Theme detection works with KDE, GNOME, GTK, and freedesktop portals
  - Monitor updates theme file; use F12 to toggle in existing terminals

ENVIRONMENT:
  FOOT_THEME_DEBUG=1     Enable debug logging in monitor mode
EOF
	;;
*)
	launch_terminal "$@"
	;;
esac
