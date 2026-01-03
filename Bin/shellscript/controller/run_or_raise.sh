#!/bin/sh
# run-or-raise: Universal app launcher that focuses if running, launches if not
# Usage: run-or-raise APP_NAME [LAUNCH_COMMAND]

# set -e # Remove -u to avoid unbound variable errors

scr_name="run-or-raise"

usage() {
	case "${1:-}" in
	"--arg") [ -n "${QUIET:-}" ] || printf "Error: Required value: %s\n" "$2" >&2 ;;
	"--bad") [ -n "${QUIET:-}" ] || printf "Error: Unknown option: %s\n" "$2" >&2 ;;
	"--app") [ -n "${QUIET:-}" ] || printf "Error: Application not provided\n" >&2 ;;
	*) ;;
	esac

	[ -n "${QUIET:-}" ] || printf "Usage: %s APP_NAME [LAUNCH_CMD]\n" "$scr_name" >&2

	if [ -n "${1:-}" ]; then exit 1; else exit 0; fi
}

parse_args() {
	while [ $# -gt 0 ]; do
		case "${1:-}" in
		"-h" | "--help") usage ;;
		"-d" | "--verbose") VERBOSE=true ;;
		"-a" | "--name")
			if [ -z "${2:-}" ]; then usage --arg "$1"; fi
			APP="$2"
			shift
			;;
		"-c" | "--cmd" | "--command")
			if [ -z "${2:-}" ]; then usage --arg "$1"; fi
			CMD="$2"
			shift
			;;
		"--")
			shift
			EXTRA_ARGS="$*"
			break
			;;
		"-?") usage --bad "$1" ;;
		"--*") usage --bad "$1" ;;
		*)
			if [ -z "${APP:-}" ]; then
				APP="$1"
			elif [ -z "${CMD:-}" ]; then
				CMD="$1"
			else
				EXTRA_ARGS="${EXTRA_ARGS:+$EXTRA_ARGS }$1"
			fi
			;;
		esac
		shift
	done

	[ -n "${APP:-}" ] || usage --app
	CMD="${CMD:-"$APP"}"
	[ -n "${VERBOSE:-}" ] && printf "Application: %s, Command: %s\n" "$APP" "$CMD" >&2
}

get_os() {
	case "$(uname -s)" in
	*[Mm][Ii][Nn][Gg][Ww]* | *[Cc][Yy][Gg][Ww][Ii][Nn]* | *[Mm][Ss][Yy][Ss]*) printf "Windows" ;;
	*[Dd][Aa][Rr][Ww][Ii][Nn]*) printf "Darwin" ;;
	*[Ll][Ii][Nn][Uu][Xx]*) printf "Linux" ;;
	*) printf "Unknown" ;;
	esac
}

# Better process detection function
is_active() {
	_app="$1"
	_cmd="$2"

	# 1. Try pgrep first (fast and reliable)
	if command -v pgrep >/dev/null 2>&1; then
		# Try app name as process name
		if pgrep -x "$_app" >/dev/null 2>&1; then
			[ -n "${VERBOSE:-}" ] && printf "Process found (pgrep -x): %s\n" "$_app" >&2
			return 0
		fi

		# Try command name
		if [ "$_app" != "$_cmd" ] && pgrep -x "$_cmd" >/dev/null 2>&1; then
			[ -n "${VERBOSE:-}" ] && printf "Process found (pgrep -x cmd): %s\n" "$_cmd" >&2
			return 0
		fi

		# Try partial match
		if pgrep -f "$_app" >/dev/null 2>&1; then
			[ -n "${VERBOSE:-}" ] && printf "Process found (pgrep -f): %s\n" "$_app" >&2
			return 0
		fi
	fi

	# 2. Try pidof
	if command -v pidof >/dev/null 2>&1; then
		if pidof -x "$_app" >/dev/null 2>&1; then
			[ -n "${VERBOSE:-}" ] && printf "Process found (pidof): %s\n" "$_app" >&2
			return 0
		fi
	fi

	# 3. Try ps with multiple approaches
	# BSD style (macOS, some Linux)
	# shellcheck disable=SC2009
	if ps aux 2>/dev/null | grep -v grep | grep -q "[[:space:]]$_app"; then
		[ -n "${VERBOSE:-}" ] && printf "Process found (ps aux): %s\n" "$_app" >&2
		return 0
	fi

	# POSIX style
	# shellcheck disable=SC2009
	if ps -e 2>/dev/null | grep -v grep | grep -q "[[:space:]]$_app"; then
		[ -n "${VERBOSE:-}" ] && printf "Process found (ps -e): %s\n" "$_app" >&2
		return 0
	fi

	# 4. Try procfs (Linux only)
	if [ -d "/proc" ]; then
		for _pid in /proc/[0-9]*; do
			[ -r "$_pid/comm" ] && [ -r "$_pid/cmdline" ] || continue

			# Check process name
			if grep -q "^$_app$" "$_pid/comm" 2>/dev/null; then
				[ -n "${VERBOSE:-}" ] && printf "Process found (procfs comm): %s\n" "$_app" >&2
				return 0
			fi

			# Check command line
			if tr '\0' ' ' <"$_pid/cmdline" 2>/dev/null | grep -q "$_app"; then
				[ -n "${VERBOSE:-}" ] && printf "Process found (procfs cmdline): %s\n" "$_app" >&2
				return 0
			fi
		done
	fi

	[ -n "${VERBOSE:-}" ] && printf "Process NOT found: %s\n" "$_app" >&2
	return 1
}

launch() {
	_app="$1"
	_cmd="$2"
	_extra="${3:-}"

	[ -n "${VERBOSE:-}" ] && printf "Launching: %s\n" "$_cmd" >&2

	if [ -n "$_extra" ]; then
		#> Use eval to handle complex arguments properly
		eval "$_cmd $_extra" &
	else
		"$_cmd" &
	fi
}

focus() {
	_app="$1"
	_success=1

	case "$(get_os)" in
	"Linux")
		#> Check if it's Wayland or X11
		if [ -n "${WAYLAND_DISPLAY:-}" ] ||
			[ "${XDG_SESSION_TYPE:-}" = "wayland" ]; then
			[ -n "${VERBOSE:-}" ] && printf "Detected Wayland session\n" >&2

			#~@ Hyprland
			if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ] && command -v hyprctl >/dev/null 2>&1; then
				[ -n "${VERBOSE:-}" ] && printf "Trying Hyprland...\n" >&2
				if hyprctl dispatch focuswindow "class:$_app" >/dev/null 2>&1; then
					[ -n "${VERBOSE:-}" ] && printf "Focused via Hyprland\n" >&2
					return 0
				fi
			fi

			#~@ Sway
			if [ -n "${SWAYSOCK:-}" ] && command -v swaymsg >/dev/null 2>&1; then
				[ -n "${VERBOSE:-}" ] && printf "Trying Sway...\n" >&2
				if swaymsg "[app_id=\"$_app\"] focus" >/dev/null 2>&1; then
					[ -n "${VERBOSE:-}" ] && printf "Focused via Sway\n" >&2
					return 0
				fi
			fi

			#~@ Plasma Wayland
			if [ -n "${KDE_FULL_SESSION:-}" ] ||
				[ "${XDG_CURRENT_DESKTOP:-}" = "KDE" ] ||
				[ "${DESKTOP_SESSION:-}" = "plasma" ] ||
				[ "${DESKTOP_SESSION:-}" = "plasmawayland" ]; then
				[ -n "${VERBOSE:-}" ] && printf "Detected KDE Plasma (Wayland)\n" >&2

				#~@ Method 1: Try using qdbus
				if command -v qdbus >/dev/null 2>&1; then
					[ -n "${VERBOSE:-}" ] && printf "Trying qdbus...\n" >&2
					#> Get list of windows and try to find our app
					_windows=$(qdbus org.kde.KWin /KWin org.kde.KWin.windows 2>/dev/null || true)
					for _win in $_windows; do
						_class=$(qdbus org.kde.KWin /KWin org.kde.KWin.getWindowInfo "$_win" 2>/dev/null | grep "resourceName" | cut -d'=' -f2 || true)
						if [ "$_class" = "$_app" ]; then
							qdbus org.kde.KWin /KWin org.kde.KWin.activateWindow "$_win" >/dev/null 2>&1 && return 0
						fi
					done
				fi

				#~@ Method 2: Try using kstart5
				if command -v kstart5 >/dev/null 2>&1; then
					[ -n "${VERBOSE:-}" ] && printf "Trying kstart5...\n" >&2
					kstart5 --windowclass "$_app" --activate >/dev/null 2>&1 && return 0
				fi
			fi

			#~@ GNOME Wayland
			if [ -n "${GNOME_DESKTOP_SESSION_ID:-}" ] ||
				[ "${XDG_CURRENT_DESKTOP:-}" = "GNOME" ]; then
				[ -n "${VERBOSE:-}" ] && printf "Detected GNOME (Wayland)\n" >&2

				#> Try using busctl (GNOME Shell)
				if command -v busctl >/dev/null 2>&1; then
					[ -n "${VERBOSE:-}" ] && printf "Trying busctl...\n" >&2
					busctl --user call org.gnome.Shell /org/gnome/Shell org.gnome.Shell Eval s \
						"global.get_window_actors().forEach(function(w){var m=w.meta_window; if(m.get_wm_class()==='$_app'){m.activate(global.get_current_time());}});" \
						>/dev/null 2>&1 && return 0
				fi
			fi
		fi

		#~@ X11 (fallback for both Wayland with XWayland and native X11)
		if [ -n "${DISPLAY:-}" ]; then
			[ -n "${VERBOSE:-}" ] && printf "Trying X11 methods...\n" >&2

			#> wmctrl - best for EWMH-compliant WMs
			if command -v wmctrl >/dev/null 2>&1; then
				[ -n "${VERBOSE:-}" ] && printf "Trying wmctrl...\n" >&2

				#> Try exact class match first
				if wmctrl -x -a "$_app" >/dev/null 2>&1; then
					[ -n "${VERBOSE:-}" ] && printf "Focused via wmctrl (exact)\n" >&2
					return 0
				fi

				#> Try capitalized version (e.g., foot -> Foot)
				_app_cap=$(echo "$_app" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}')
				if wmctrl -x -a "$_app_cap" >/dev/null 2>&1; then
					[ -n "${VERBOSE:-}" ] && printf "Focused via wmctrl (capitalized)\n" >&2
					return 0
				fi

				#> Try app.App format (e.g., foot.Foot)
				if wmctrl -x -a "$_app.$_app_cap" >/dev/null 2>&1; then
					[ -n "${VERBOSE:-}" ] && printf "Focused via wmctrl (app.App)\n" >&2
					return 0
				fi

				#> Try by window name/description
				if wmctrl -a "$_app" >/dev/null 2>&1; then
					[ -n "${VERBOSE:-}" ] && printf "Focused via wmctrl (by name)\n" >&2
					return 0
				fi
			fi

			#> Try xdotool fallback
			if command -v xdotool >/dev/null 2>&1; then
				[ -n "${VERBOSE:-}" ] && printf "Trying xdotool...\n" >&2

				#> Search for window by class
				_winid=$(xdotool search --class "$_app" 2>/dev/null | head -1)
				if [ -n "$_winid" ]; then
					xdotool windowactivate "$_winid" >/dev/null 2>&1
					if [ $? -eq 0 ]; then
						[ -n "${VERBOSE:-}" ] && printf "Focused via xdotool (class)\n" >&2
						return 0
					fi
				fi

				#> Search by window name
				_winid=$(xdotool search --name "$_app" 2>/dev/null | head -1)
				if [ -n "$_winid" ]; then
					xdotool windowactivate "$_winid" >/dev/null 2>&1
					if [ $? -eq 0 ]; then
						[ -n "${VERBOSE:-}" ] && printf "Focused via xdotool (name)\n" >&2
						return 0
					fi
				fi
			fi

			#~@ Plasma X11
			if [ -n "${KDE_FULL_SESSION:-}" ] ||
				[ "${XDG_CURRENT_DESKTOP:-}" = "KDE" ] ||
				[ "${DESKTOP_SESSION:-}" = "plasma" ] ||
				[ "${DESKTOP_SESSION:-}" = "kde-plasma" ]; then
				[ -n "${VERBOSE:-}" ] &&
					printf "Detected KDE Plasma (X11)\n" >&2

				#> Try kstart (for older KDE)
				if command -v kstart >/dev/null 2>&1; then
					[ -n "${VERBOSE:-}" ] && printf "Trying kstart...\n" >&2
					kstart --windowclass "$_app" --activate >/dev/null 2>&1 && return 0
				fi

				#> Try kstart5 (for newer KDE)
				if command -v kstart5 >/dev/null 2>&1; then
					[ -n "${VERBOSE:-}" ] && printf "Trying kstart5...\n" >&2
					kstart5 --windowclass "$_app" --activate >/dev/null 2>&1 && return 0
				fi
			fi
		fi
		;;
	"Darwin")
		[ -n "${VERBOSE:-}" ] && printf "Trying macOS methods...\n" >&2
		#> Try System Events first, then direct activation
		osascript -e "tell application \"System Events\" to tell process \"$_app\" to perform action \"AXRaise\" of window 1" >/dev/null 2>&1 && return 0
		osascript -e "tell application \"$_app\" to activate" >/dev/null 2>&1 && return 0
		;;
	"Windows")
		[ -n "${VERBOSE:-}" ] && printf "Trying Windows methods...\n" >&2
		powershell -Command "
      \$ErrorActionPreference='SilentlyContinue'\`
      \$wshell = New-Object -ComObject wscript.shell \`
      \$wshell.AppActivate('$_app')
      " >/dev/null 2>&1 && return 0
		;;
	esac

	[ -n "${VERBOSE:-}" ] &&
		printf "All focus methods failed for: %s\n" "$_app" >&2
	return 1
}

main() {
	parse_args "$@"

	#> First try to focus existing window
	if focus "$APP"; then
		printf "Focused existing window: %s\n" "$APP" >&2
		exit 0
	fi

	#> Check if process exists
	if is_active "$APP" "$CMD"; then
		#? Process exists but we couldn't focus the window
		printf "Note: '%s' is running but couldn't be focused\n" "$APP" >&2

		#> Try one more aggressive focus attempt
		[ -n "${VERBOSE:-}" ] &&
			printf "Trying alternative focus methods...\n" >&2

		#> For X11, try to find any window containing app name
		if [ -n "${DISPLAY:-}" ] &&
			command -v xdotool >/dev/null 2>&1; then
			_winid=$(
				xdotool search --onlyvisible --name ".*" 2>/dev/null |
					while read -r id; do
						if xdotool getwindowname "$id" 2>/dev/null | grep -q "$APP"; then
							printf "%s" "$id"
							break
						fi
					done
			)

			if [ -n "$_winid" ]; then
				xdotool windowactivate "$_winid" >/dev/null 2>&1
				if [ $? -eq 0 ]; then
					printf "Managed to focus window via alternative method\n" >&2
					exit 0
				fi
			fi
		fi

		exit 1
	fi

	#> Launch new instance
	[ -n "${VERBOSE:-}" ] &&
		printf "Launching new instance: %s\n" "$CMD" >&2
	launch "$APP" "$CMD" "${EXTRA_ARGS:-}"
	exit 0
}

main "$@"
