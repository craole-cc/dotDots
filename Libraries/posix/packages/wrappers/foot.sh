#!/bin/sh
# shellcheck enable=all
# ~@ Feet - Smart Foot Terminal Wrapper
# ? POSIX-compliant terminal launcher
# ? Location: $DOTS/Bin/shellscript/packages/wrappers/feet.sh
# ?
# ? Theme detection and verbosity resolution are delegated to the
# ? `colorscheme` and `verbosity` tools rather than reimplemented here
# ? -- this script used to carry its own copy of the KDE/portal/GNOME/
# ? GTK detection cascade and its own bool/env verbosity parsing; both
# ? are now single-source-of-truth elsewhere. See resolve_tool() (from
# ? the shared lib below) for how their paths are found.

#> Locate & source the shared resolve-tool library (has_cmd,
#? resolve_tool, run_tool, require_tool). Inlined rather than calling
#? resolve_tool itself, since that isn't defined until this succeeds.
#? Same override -> relative-path -> PATH cascade philosophy as
#? resolve_tool proper, just self-contained for this bootstrap step.
if [ -n "${CMD_RESOLVE_TOOL_LIB:-}" ] && [ -f "${CMD_RESOLVE_TOOL_LIB}" ]; then
  . "${CMD_RESOLVE_TOOL_LIB}"
else
  _rt_self_dir=$(dirname -- "$0" 2>/dev/null) || _rt_self_dir="."
  _rt_candidate="${_rt_self_dir}/../../lib/resolve-tool.sh"
  if [ -f "${_rt_candidate}" ]; then
    . "${_rt_candidate}"
  elif command -v resolve-tool.sh >/dev/null 2>&1; then
    . "$(command -v resolve-tool.sh)"
  else
    printf "Error: resolve-tool.sh library not found (CMD_RESOLVE_TOOL_LIB, relative path, or PATH)\n" >&2
    exit 1
  fi
  unset _rt_self_dir _rt_candidate
fi

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

  #> Resolve tool paths once, so detect_scheme/log_debug/etc never
  #? need to re-run this lookup. Missing tools are reported here, up
  #? front, rather than surfacing later as an opaque failure.
  COLORSCHEME_CMD=$(resolve_tool "colorscheme" "CMD_COLORSCHEME" "$0" "../../interface/theme/colorscheme") ||
    printf "Warning: colorscheme not found (CMD_COLORSCHEME, relative path, or PATH); theme detection will default to dark.\n" >&2
  VERBOSITY_CMD=$(resolve_tool "verbosity" "CMD_VERBOSITY" "$0" "../../output/verbosity") ||
    printf "Warning: verbosity not found (CMD_VERBOSITY, relative path, or PATH); defaulting to level 3.\n" >&2

  #> Resolve verbosity ONCE, numerically, via the `verbosity` tool.
  #? Everything else in this script just compares $LEVEL with [ ], via
  #? is_debug(). This keeps env-var precedence, color/name aliases,
  #? and +N/-N handling all owned by `verbosity` itself -- this script
  #? never re-parses VERBOSE/DEBUG/verbosity env vars on its own.
  if [ -n "${VERBOSITY_CMD:-}" ]; then
    LEVEL=$(run_tool "${VERBOSITY_CMD}")
  else
    LEVEL=3
  fi
}

is_debug() {
  [ "${LEVEL:-3}" -ge 4 ]
}

log_debug() {
  if is_debug; then
    printf "[Debug] %s\n" "$1" >&2
  fi
}

#? --- Argument handling ----------------------------------------------------

parse_arguments() {
  case "${1:-}" in
  --monitor | -m)
    shift
    strip_verbose_flag "$@"
    #shellcheck disable=SC2086
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
    #shellcheck disable=SC2086
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

#| Pulls -v/--verbose out of "$@" (wherever it appears) and bumps
#? $LEVEL to at least debug (4) via `verbosity`'s increment support,
#? leaving everything else in STRIPPED_ARGS. This is what makes a
#? one-off `-v` flag on --detect/--monitor compose with whatever
#? $LEVEL was already resolved to at startup, instead of just forcing
#? a fixed value.
strip_verbose_flag() {
  STRIPPED_ARGS=""
  for arg in "$@"; do
    case "${arg}" in
    -v | --verbose)
      if [ -n "${VERBOSITY_CMD:-}" ]; then
        LEVEL=$(run_tool "${VERBOSITY_CMD}" --level "${LEVEL:-3}" --default "${LEVEL:-3}" +1)
      else
        #? verbosity tool unavailable -- fall back to a plain bump,
        #? clamped to the same 0-5 range verbosity itself enforces.
        LEVEL=$((${LEVEL:-3} + 1))
        [ "${LEVEL}" -gt 5 ] && LEVEL=5
      fi
      ;;
    *)
      STRIPPED_ARGS="${STRIPPED_ARGS} ${arg}"
      ;;
    esac
  done
}

#| Detects the active light/dark theme by delegating to `colorscheme
#? --get`, which already implements (and keeps up to date) the full
#? DMS/darkman/Plasma/portal/GNOME/GTK/env/time-based detection
#? cascade -- duplicating that logic here was the thing we were
#? trying to get away from.
detect_scheme() {
  if [ -z "${COLORSCHEME_CMD:-}" ]; then
    log_debug "colorscheme unavailable, defaulting to dark"
    printf "dark"
    return 1
  fi

  scheme=$(run_tool "${COLORSCHEME_CMD}" --get 2>/dev/null)
  case "${scheme}" in
  light | dark)
    printf "%s" "${scheme}"
    log_debug "Source: ${COLORSCHEME_CMD} --get"
    return 0
    ;;
  *)
    #> colorscheme returned something unexpected -- fall back to a
    #? safe default rather than propagating garbage into
    #? start_server, which only understands "dark"/"light".
    log_debug "${COLORSCHEME_CMD} --get returned '${scheme}', defaulting to dark"
    printf "dark"
    return 1
    ;;
  esac
}

start_server() {
  theme="$1"
  case "${theme}" in
  dark | light) foot_theme="${theme}" ;;
  *) foot_theme="dark" ;;
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
  - Theme detection and verbosity resolution are delegated to the
    \`colorscheme\` and \`verbosity\` tools, found via the shared
    lib/resolve-tool.sh library's resolve_tool(), in order:
      1. CMD_COLORSCHEME / CMD_VERBOSITY env var, if set
      2. relative to this script's own location (e.g. alongside it
         in the same Nix store path)
      3. on PATH
    If neither tool can be found, theme detection defaults to dark
    and verbosity defaults to level 3, with a warning on startup.
  - lib/resolve-tool.sh itself is located the same way (env override,
    then ../../lib/resolve-tool.sh relative to this script, then
    PATH) -- see the bootstrap block at the top of this file. Set
    CMD_RESOLVE_TOOL_LIB to pin it explicitly (e.g. from a Nix
    wrapper).
  - Monitor updates theme file; use F12 to toggle in existing terminals
  - -v/--verbose on --detect/--monitor bumps the already-resolved
    verbosity level by one step (via \`verbosity ... +1\`), it doesn't
    just force a fixed value

ENVIRONMENT:
  CMD_COLORSCHEME        Explicit path to the colorscheme tool
  CMD_VERBOSITY          Explicit path to the verbosity tool
  CMD_RESOLVE_TOOL_LIB   Explicit path to lib/resolve-tool.sh

  Verbosity is resolved once at startup via \`verbosity\` -- see
  \`verbosity --help\` for the full set of recognized environment
  variables (VERBOSITY, verbosity, debug=1, etc.)
EOF
}

initialize_environment
parse_arguments "$@"
