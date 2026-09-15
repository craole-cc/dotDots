#!/bin/sh
# shellcheck enable=all
# ~@ Feet - Smart Foot Terminal Wrapper
# ? POSIX-compliant theme detection and terminal launcher
# ? Location: $DOTS/Bin/shellscript/packages/wrappers/feet.sh

initialize_environment() {
  #> Early exit if not on Wayland
  if [ -z "${WAYLAND_DISPLAY:-}" ]; then
    printf "Error: Foot requires Wayland. WAYLAND_DISPLAY is not set.\n" >&2
    exit 1
  else
    USER_ID=$(id -u)
    THEME_FILE="/tmp/foot-theme-${USER_ID:?}"
    SOCKET="/run/user/${USER_ID:?}/foot-${WAYLAND_DISPLAY}.sock"
  fi

  set_global_verbosity
}

#? --- Global verbosity ----------------------------------------------------
#? Verbosity used to be resolved separately in two places: detect_scheme
#? parsed its own -v/--verbose flag and a `verbosity` env var, while
#? monitor_mode had a completely separate FOOT_THEME_DEBUG toggle. That
#? meant `feet --monitor -v` didn't work, and every new function that
#? wanted debug output had to reinvent the check.
#?
#? Now it's resolved ONCE, here, into a single $VERBOSE flag. Everything
#? else in the script just calls is_verbose() / log_debug() and never
#? touches an env var directly.
#?
#? Enabled by any of:
#?   - -v / --verbose      CLI flag, anywhere in the --detect/--monitor args
#?   - FOOT_THEME_DEBUG=1  env var (kept for backwards compatibility)
#?   - verbosity=4         env var (any value > 3, kept for compatibility)
#?
#? All of these are normalized through `case`, not `[ -eq ]`/`[ -gt ]`,
#? so a stray non-numeric or oddly-cased value (VERBOSE=True, verbosity=abc,
#? FOOT_THEME_DEBUG=yes) can never throw a comparison error or silently
#? behave differently depending on where it's checked.

# Normalize a fuzzy truthy value (1, true, yes, on -- any case) down to a
# clean "1" or "0". Anything unrecognized -> "0".
normalize_bool() {
  case "$1" in
  1 | [Tt][Rr][Uu][Ee] | [Yy][Ee][Ss] | [Yy] | [Oo][Nn])
    printf "1"
    ;;
  *)
    printf "0"
    ;;
  esac
}

set_global_verbosity() {
  # Capture any pre-set VERBOSE from the calling environment before we
  # start using the VERBOSE name as our own internal flag.
  _env_verbose=$(normalize_bool "${VERBOSE:-0}")
  _debug_env=$(normalize_bool "${FOOT_THEME_DEBUG:-0}")

  VERBOSE=0
  case "${_env_verbose}${_debug_env}" in
  *1*)
    VERBOSE=1
    ;;
  *)
    VERBOSE=0
    ;;
  esac

  # `verbosity` is a numeric threshold (>3), not a bool, so normalize it
  # by shape first: only single/multi-digit input is ever treated as
  # numeric, anything else (empty, "abc", "4x") is treated as "not set"
  # rather than tripping a comparison error.
  case "${verbosity:-}" in
  '' | *[!0-9]*)
    : # unset or non-numeric -- leave VERBOSE as-is
    ;;
  *)
    if [ "${verbosity}" -gt 3 ]; then
      VERBOSE=1
    fi
    ;;
  esac

  unset _env_verbose _debug_env
}

is_verbose() {
  case "${VERBOSE:-0}" in
  1) return 0 ;;
  *) return 1 ;;
  esac
}

log_debug() {
  if is_verbose; then
    printf "[Debug] %s\n" "$1" >&2
  fi
}

#? --- Argument handling ----------------------------------------------------

parse_arguments() {
  case "${1:-}" in
  --monitor | -m)
    shift
    strip_verbose_flag "$@"
    # shellcheck disable=SC2086
    set -- ${STRIPPED_ARGS}
    monitor_mode "$@"
    ;;
  --quake | -q)
    shift
    quake_mode
    ;;
  --detect | -d)
    shift
    strip_verbose_flag "$@"
    # shellcheck disable=SC2086
    set -- ${STRIPPED_ARGS}
    detect_scheme "$@"
    printf "\n"
    ;;
  --help | -h)
    print_help
    ;;
  *)
    launch_terminal "$@"
    ;;
  esac
}

# Pulls -v/--verbose out of "$@" (wherever it appears), sets the global
# VERBOSE flag, and leaves everything else in STRIPPED_ARGS. This is what
# makes verbosity "global": individual functions no longer parse -v
# themselves, they just read $VERBOSE via is_verbose()/log_debug().
strip_verbose_flag() {
  STRIPPED_ARGS=""
  for arg in "$@"; do
    case "${arg}" in
    -v | --verbose)
      VERBOSE=1
      ;;
    *)
      STRIPPED_ARGS="${STRIPPED_ARGS} ${arg}"
      ;;
    esac
  done
}

has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

detect_scheme() {
  # Verbosity is already resolved globally by the time we get here (env
  # vars in set_global_verbosity, plus any -v/--verbose flag stripped out
  # by parse_arguments/strip_verbose_flag).

  _report() {
    printf "%s" "$1"
    log_debug "Source: $2"
  }

  # Respect XDG_CONFIG_HOME if set, otherwise fallback to default
  xdg_conf_home="${XDG_CONFIG_HOME:-${HOME}/.config}"

  # 1. Check KDE Plasma
  kdeglobals="${xdg_conf_home}/kdeglobals"
  if [ -f "${kdeglobals}" ]; then
    scheme=$(grep -m1 "^ColorScheme=" "${kdeglobals}" | cut -d= -f2)
    case "${scheme}" in
    *[Dd]ark*)
      _report "dark" "KDE Plasma (kdeglobals ColorScheme)"
      return 0
      ;;
    *[Ll]ight*)
      _report "light" "KDE Plasma (kdeglobals ColorScheme)"
      return 0
      ;;
    *) ;;
    esac

    # Fallback for older KDE settings
    inactive_color=$(
      grep -A5 "^\[ColorEffects:Inactive\]" "${kdeglobals}" 2>/dev/null |
        grep -m1 "^Color=" | cut -d= -f2
    )
    if [ -n "${inactive_color}" ]; then
      red=$(printf '%s' "${inactive_color}" | cut -d, -f1)
      if [ "${red}" -gt 100 ] 2>/dev/null; then
        _report "light" "KDE Plasma (kdeglobals ColorEffects)"
        return 0
      else
        _report "dark" "KDE Plasma (kdeglobals ColorEffects)"
        return 0
      fi
    fi
  fi

  # 2. Check freedesktop portal (dbus)
  if has_cmd dbus-send; then
    scheme=$(
      dbus-send \
        --session \
        --print-reply=literal \
        --reply-timeout=100 \
        --dest=org.freedesktop.portal.Desktop \
        /org/freedesktop/portal/desktop \
        org.freedesktop.portal.Settings.Read \
        string:'org.freedesktop.appearance' string:'color-scheme' 2>/dev/null |
        grep -oE 'uint32 [0-9]+' | awk '{print $2}'
    )

    case "${scheme}" in
    1)
      _report "dark" "Freedesktop Portal (dbus)"
      return 0
      ;;
    2)
      _report "light" "Freedesktop Portal (dbus)"
      return 0
      ;;
    *) ;;
    esac
  fi

  # 3. Check GNOME settings (gsettings)
  if has_cmd gsettings; then
    scheme=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null)
    case "${scheme}" in
    *dark*)
      _report "dark" "GNOME (gsettings)"
      return 0
      ;;
    *light*)
      _report "light" "GNOME (gsettings)"
      return 0
      ;;
    *) ;;
    esac
  fi

  # 4. Check GTK theme
  for conf in \
    "${xdg_conf_home}/gtk-4.0/settings.ini" \
    "${xdg_conf_home}/gtk-3.0/settings.ini"; do
    if [ -f "${conf}" ]; then
      scheme=$(grep -m1 "^gtk-theme-name" "${conf}" | cut -d= -f2 | tr -d ' "')
      case "${scheme}" in
      *[Dd]ark*)
        _report "dark" "GTK Theme (${conf})"
        return 0
        ;;
      *[Ll]ight*)
        _report "light" "GTK Theme (${conf})"
        return 0
        ;;
      *) ;;
      esac
    fi
  done

  # 5. Check environment variables (Combined QT and GTK check)
  case "${QT_STYLE_OVERRIDE:-}:${GTK_THEME:-}" in
  *[Dd]ark*)
    _report "dark" "Environment Variables (QT_STYLE_OVERRIDE/GTK_THEME)"
    return 0
    ;;
  *[Ll]ight*)
    _report "light" "Environment Variables (QT_STYLE_OVERRIDE/GTK_THEME)"
    return 0
    ;;
  *) ;;
  esac

  # 6. Time-based fallback
  hour=$(date +%H)
  if [ "${hour}" -ge 6 ] && [ "${hour}" -lt 18 ]; then
    _report "light" "Time-based fallback (${hour}:00)"
  else
    _report "dark" "Time-based fallback (${hour}:00)"
  fi
}

start_server() {
  theme="$1"
  case "${theme}" in
  dark | light)
    foot_theme="${theme}"
    ;;
  *)
    foot_theme="dark"
    ;;
  esac

  foot_bin=$(command -v foot 2>/dev/null) || {
    printf "Error: foot not in PATH\n" >&2
    return 1
  }

  log_debug "Starting foot server with theme=${foot_theme}"
  "${foot_bin}" --server -o main.initial-color-theme="${foot_theme}" >/dev/null 2>&1 &
  return 0
}

wait_for_socket() {
  socket="$1"
  max_wait="${2:-10}" # Default 10s
  i=0
  while [ "${i}" -lt $((max_wait * 10)) ]; do # 0.1s intervals
    if [ -S "${socket}" ]; then
      log_debug "Socket ${socket} ready after $((i * 100))ms"
      sleep 0.5
      return 0
    fi
    sleep 0.1
    i=$((i + 1))
  done
  printf "Timeout waiting for %s\n" "${socket}" >&2
  return 1
}

launch_with_server() {
  theme_file="$1"
  socket="$2"
  theme="$3"
  client_cmd="$4"

  #> Cleanup stale socket
  [ -S "${socket}" ] && ! pgrep -x foot >/dev/null 2>&1 && rm -f "${socket}"

  #? Server check → start/connect
  if ! pgrep -x foot >/dev/null 2>&1 || [ ! -S "${socket}" ]; then
    log_debug "No running foot server found, starting one"
    printf '%s' "${theme}" >"${theme_file}"
    rm -f "${socket}"
    start_server "${theme}" || return 1
    wait_for_socket "${socket}" || return 1
  else
    log_debug "Reusing existing foot server at ${socket}"
  fi

  #? Connect (shift client args)
  shift 4
  exec "${client_cmd}" --server-socket="${socket}" "$@"
}

monitor_mode() {
  # Verbosity is already resolved globally by the time we get here.

  printf "Starting foot theme monitor...\n" >&2

  # Initialize theme file
  CURRENT_THEME=$(detect_scheme)
  printf '%s' "${CURRENT_THEME}" >"${THEME_FILE}"
  printf "Initial theme: %s\n" "${CURRENT_THEME}" >&2

  while true; do
    sleep 2
    NEW_THEME=$(detect_scheme)

    log_debug "Checked theme: ${NEW_THEME}"

    if [ -f "${THEME_FILE}" ]; then
      LAST_THEME=$(cat "${THEME_FILE}")

      if [ "${LAST_THEME}" != "${NEW_THEME}" ]; then
        printf "Theme changed: %s → %s\n" "${LAST_THEME}" "${NEW_THEME}" >&2
        printf '%s' "${NEW_THEME}" >"${THEME_FILE}"
        printf "Press F12 in terminals to toggle theme, or close and reopen them.\n" >&2
      fi
    fi
  done
}

find_window_id() {
  #> Get list of all windows
  windows=$(qdbus org.kde.KWin /KWin org.kde.KWin.windows 2>/dev/null)
  for window in ${windows}; do
    #> Get window info and check if it matches our appId
    info=$(qdbus org.kde.KWin /KWin org.kde.KWin.queryWindowInfo "${window}" 2>/dev/null)
    if printf "%s" "${info}" | grep -q "appId: $1"; then
      printf "%s" "${window}"
      return 0
    fi
  done
  printf ""
}

quake_mode() {
  QUAKE_ID="foot-quake"
  WINDOW_ID=$(find_window_id "${QUAKE_ID}")

  if [ -n "${WINDOW_ID:-}" ]; then
    #? Window exists, check its state and toggle it
    WINDOW_INFO=$(qdbus org.kde.KWin /KWin org.kde.KWin.queryWindowInfo "${WINDOW_ID}" 2>/dev/null)

    if printf "%s" "${WINDOW_INFO}" | grep -q "minimized: true"; then
      #> Window is minimized, show it
      log_debug "Quake window ${WINDOW_ID} is minimized, unminimizing"
      qdbus org.kde.KWin /KWin org.kde.KWin.unminimizeWindow "${WINDOW_ID}" 2>/dev/null
      qdbus org.kde.KWin /KWin org.kde.KWin.activateWindow "${WINDOW_ID}" 2>/dev/null
    elif printf "%s" "${WINDOW_INFO}" | grep -q "active: true"; then
      #> Window is active and visible, hide it
      log_debug "Quake window ${WINDOW_ID} is active, minimizing"
      qdbus org.kde.KWin /KWin org.kde.KWin.minimizeWindow "${WINDOW_ID}" 2>/dev/null
    else
      #> Window exists but not active, activate it
      log_debug "Quake window ${WINDOW_ID} exists but inactive, activating"
      qdbus org.kde.KWin /KWin org.kde.KWin.activateWindow "${WINDOW_ID}" 2>/dev/null
    fi
  else
    #> Window doesn't exist, launch it
    log_debug "No quake window found, launching a new one"
    detected_mode=$(detect_scheme)
    echo "${detected_mode}"
    launch_with_server "${THEME_FILE}" "${SOCKET}" "${detected_mode}" footclient \
      --app-id="${QUAKE_ID}" \
      --window-size-chars=240x40 \
      >/dev/null 2>&1 &
  fi
}

launch_terminal() {
  theme=$(detect_scheme)
  launch_with_server "${THEME_FILE}" "${SOCKET}" "${theme}" footclient "$@"
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
  --detect, -d     Detect and print current theme (dark/light). Use -v for source.
  --help, -h       Show this help message

EXAMPLES:
  feet                    # Launch terminal
  feet --monitor          # Start theme monitor daemon
  feet --monitor -v       # Start theme monitor with debug logging
  feet --detect -v        # Check current theme and show detection source
  feet -e nvim file.txt   # Launch terminal running nvim

NOTES:
  - Requires foot terminal emulator installed
  - Theme detection works with KDE, GNOME, GTK, and freedesktop portals
  - Monitor updates theme file; use F12 to toggle in existing terminals
  - -v/--verbose is resolved globally: it works no matter where it
    appears in the --detect/--monitor arguments, and now also turns on
    debug logging in monitor mode (previously only FOOT_THEME_DEBUG did)

ENVIRONMENT:
  FOOT_THEME_DEBUG=1      Enable debug logging globally (legacy name)
  verbosity=4             Enable debug logging globally (any value > 3)
EOF
}

initialize_environment
parse_arguments "$@"
