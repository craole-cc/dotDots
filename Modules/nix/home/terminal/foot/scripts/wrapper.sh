#!/bin/sh
# shellcheck enable=all
#~@ Feet - Smart Foot Terminal Wrapper
#? POSIX-compliant theme detection and terminal launcher
#? Location: $DOTS/Bin/shellscript/packages/wrappers/feet.sh

initialize_environment() {
	#> Early exit if not on Wayland
	if [ -z "${WAYLAND_DISPLAY:-}" ]; then
		printf "Error: Foot requires Wayland. WAYLAND_DISPLAY is not set.\n" >&2
		exit 1
	else
		USER_ID=$(id -u)
		THEME_FILE="/tmp/foot-theme-$USER_ID"
		SOCKET="/run/user/$USER_ID/foot-${WAYLAND_DISPLAY}.sock"
	fi
}

parse_arguments() {
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
	--help | -h) print_help ;;
	*)
		launch_terminal "$@"
		;;
	esac
}

has_cmd() {
	command -v "$1" >/dev/null 2>&1
}

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

start_server() {
	theme="$1"
	case "$theme" in
	dark | light) foot_theme="$theme" ;;
	*) foot_theme="dark" ;;
	esac

	foot_bin=$(command -v feet 2>/dev/null || command -v foot)
	[ -n "${foot_bin:-}" ] || {
		printf "Error: foot/feet not in PATH\n" >&2
		return 1
	}

	"${foot_bin}" --server -o main.initial-color-theme="${foot_theme}" >/dev/null 2>&1 &
	return 0
}

wait_for_socket() {
	socket="$1"
	max_wait="${2:-10}" # Default 10s
	i=0
	while [ "$i" -lt $((max_wait * 10)) ]; do # 0.1s intervals
		if [ -S "$socket" ]; then
			sleep 0.5
			return 0
		fi
		sleep 0.1
		i=$((i + 1))
	done
	printf "Timeout waiting for %s\n" "$socket" >&2
	return 1
}

launch_with_server() {
	theme_file="$1"
	socket="$2"
	theme="$3"
	client_cmd="$4"

	#> Cleanup stale socket
	[ -S "$socket" ] && ! pgrep -x foot >/dev/null 2>&1 && rm -f "$socket"

	#? Server check → start/connect
	if ! pgrep -x foot >/dev/null 2>&1 || [ ! -S "$socket" ]; then
		printf '%s' "$theme" >"$theme_file"
		rm -f "$socket"
		start_server "$theme" || return 1
		wait_for_socket "$socket" || return 1
	fi

	#? Connect (shift client args)
	shift 4
	exec "$client_cmd" --server-socket="$socket" "$@"
}

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

find_window_id() {
	#> Get list of all windows
	windows=$(qdbus org.kde.KWin /KWin org.kde.KWin.windows 2>/dev/null)
	for window in $windows; do
		#> Get window info and check if it matches our appId
		info=$(qdbus org.kde.KWin /KWin org.kde.KWin.queryWindowInfo "$window" 2>/dev/null)
		if printf "%s" "$info" | grep -q "appId: $1"; then
			printf "%s" "$window"
			return 0
		fi
	done
	printf ""
}

quake_mode() {
	QUAKE_ID="foot-quake"
	WINDOW_ID=$(find_window_id "$QUAKE_ID")

	if [ -n "${WINDOW_ID:-}" ]; then
		#? Window exists, check its state and toggle it
		WINDOW_INFO=$(qdbus org.kde.KWin /KWin org.kde.KWin.queryWindowInfo "${WINDOW_ID}" 2>/dev/null)

		if printf "%s" "${WINDOW_INFO}" | grep -q "minimized: true"; then
			#> Window is minimized, show it
			qdbus org.kde.KWin /KWin org.kde.KWin.unminimizeWindow "${WINDOW_ID}" 2>/dev/null
			qdbus org.kde.KWin /KWin org.kde.KWin.activateWindow "${WINDOW_ID}" 2>/dev/null
		elif printf "%s" "${WINDOW_INFO}" | grep -q "active: true"; then
			#> Window is active and visible, hide it
			qdbus org.kde.KWin /KWin org.kde.KWin.minimizeWindow "${WINDOW_ID}" 2>/dev/null
		else
			#> Window exists but not active, activate it
			qdbus org.kde.KWin /KWin org.kde.KWin.activateWindow "${WINDOW_ID}" 2>/dev/null
		fi
	else
		#> Window doesn't exist, launch it
		launch_with_server "${THEME_FILE}" "${SOCKET}" "$(detect_theme)" footclient \
			--app-id="${QUAKE_ID}" \
			--window-size-chars=240x40 \
			>/dev/null 2>&1 &
	fi
}

launch_terminal() {
	launch_with_server "${THEME_FILE}" "${SOCKET}" "$(detect_theme)" footclient "$@"
}

#> Main execution
print_help() {
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
}
initialize_environment
parse_arguments "$@"
