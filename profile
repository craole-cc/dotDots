#!/bin/sh
# shellcheck enable=all

# ═══════════════════════════════════════════════════════════════════════════
# SECTION: config.sh
# Metadata, runtime defaults, base paths, DOTS environment.
# ═══════════════════════════════════════════════════════════════════════════

configure() {
  # ── Metadata ────────────────────────────────────────────────────────────
  name="profile"
  home="${DOTS:-${HOME}}"
  path="${home}/${name}"
  description="Temporary bootstrap for NixOS environment"
  author="craole"
  version="0.2.6"

  # ── Runtime ─────────────────────────────────────────────────────────────
  verbosity="info" #? Levels: quiet | info | verbose | debug | dry
  command="all"    #? The active command to run
  help_requested=0
  host=$(hostname || echo "unknown host")

  # ── Base Paths ──────────────────────────────────────────────────────────
  #? Common roots reused throughout; join_path builds anything deeper.
  #? XDG vars are self-assigned with fallback and exported so any child
  #? process (or gum/gsettings/etc.) sees the same values we resolve here.
  NIX_PROFILE_DIR="$(find_nix_profile_dir)"
  VSCODE_SERVER_DIR="${HOME}/.vscode-server"
  XDG_CACHE_HOME="${XDG_CACHE_HOME:-${HOME}/.cache}"
  XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-${HOME}/.config}"
  XDG_DATA_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}"
  #? Not a standard XDG var, but ~/.local/bin shares ~/.local with
  #? XDG_DATA_HOME, so derive it from there rather than ${HOME} directly.
  XDG_BIN_HOME="${XDG_BIN_HOME:-$(join_path "$(dirname "${XDG_DATA_HOME}")" bin)}"
  XDG_DATA_DIRS="${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
  export \
    NIX_PROFILE_DIR \
    VSCODE_SERVER_DIR \
    XDG_BIN_HOME XDG_CACHE_HOME XDG_CONFIG_HOME XDG_DATA_HOME XDG_DATA_DIRS

  # ── DOTS Environment ──────────────────────────────────────────────────
  DOTS="${DOTS:-"${PWD:-"$(pwd -P)"}"}"
  DOTS_CFG="${DOTS_CFG:-"${DOTS}/Configuration"}"
  DOTS_LIB="${DOTS_LIB:-"${DOTS}/Libraries"}"
  DOTS_LIB_BASH="${DOTS_LIB_BASH:-"${DOTS_LIB}/bash"}"
  DOTS_LIB_CMD="${DOTS_LIB_CMD:-"${DOTS_LIB}/cmd"}"
  DOTS_LIB_NIX="${DOTS_LIB_NIX:-"${DOTS_LIB}/nix"}"
  DOTS_LIB_NU="${DOTS_LIB_NU:-"${DOTS_LIB}/nushell"}"
  DOTS_LIB_PS="${DOTS_LIB_PS:-"${DOTS_LIB}/powershell"}"
  DOTS_LIB_PY="${DOTS_LIB_PY:-"${DOTS_LIB}/python"}"
  DOTS_LIB_RS="${DOTS_LIB_RS:-"${DOTS_LIB}/rust"}"
  DOTS_LIB_SH="${DOTS_LIB_SH:-"${DOTS_LIB}/posix"}"
  DOTS_LIB_XML="${DOTS_LIB_XML:-"${DOTS_LIB}/xml"}"
  export DOTS DOTS_CFG DOTS_LIB DOTS_LIB_BASH DOTS_LIB_CMD DOTS_LIB_NIX DOTS_LIB_NU DOTS_LIB_PS DOTS_LIB_PY DOTS_LIB_RS DOTS_LIB_SH DOTS_LIB_XML
}

# ═══════════════════════════════════════════════════════════════════════════
# SECTION: packages.sh
# Host-specific monitor defaults + the package/dependency manifest.
# Split out if host profiles or package lists grow large enough to
# warrant their own file (e.g. one file per host).
# ═══════════════════════════════════════════════════════════════════════════

configure_host_profile() {
  case "${host}" in
  Victus)
    monitor_pri_name="HDMI-A-1"
    monitor_pri_width="1920"
    monitor_pri_height="1080"
    monitor_pri_rate="100"

    monitor_sec_name="eDP-1"
    monitor_sec_width="1920"
    monitor_sec_height="1080"
    monitor_sec_rate="144"
    monitor_sec_pos="mirror"
    monitor_sec_disable=1 #? damaged/overheating panel — force off every run

    monitor_ter_name=""
    monitor_ter_width="1920"
    monitor_ter_height="1080"
    monitor_ter_rate="60"
    monitor_ter_pos="right"
    ;;
  QBX)
    monitor_pri_name="HDMI-A-2"
    monitor_pri_width="2560"
    monitor_pri_height="1440"
    monitor_pri_rate="99.965"

    monitor_sec_name="DP-3"
    monitor_sec_width="1600"
    monitor_sec_height="900"
    monitor_sec_rate="60"
    monitor_sec_pos="left"

    monitor_ter_name=""
    monitor_ter_width="1920"
    monitor_ter_height="1080"
    monitor_ter_rate="60"
    monitor_ter_pos="right"
    ;;
  *)
    print --error "Unknown monitor setup; define profile mappings"
    return 1
    ;;
  esac
}

configure_packages() {
  packages="
    alejandra
    antigravity-cli
    antigravity-fhs
    bat
    bottom
    cfspeedtest
    darkman
    delta
    dust
    eza
    fd
    fzf
    gawk
    gh
    gnused
    gitui
    gum
    hyperfine
    hyprland
    lorri
    nix-ld
    nodejs
    ollama
    ripgrep
    rustup
    shellcheck
    shfmt
    shortwave
    speedtest-go
    speedtest-rs
    sudo
    tailscale
    tealdeer
    tokei
    wl-clipboard
    xdg-desktop-portal
    xdg-desktop-portal-hyprland
    zoxide
  "
  dependencies_required="gawk gnused lorri ripgrep fd sudo"
  dependencies_optional="
    bat
    bottom
    darkman
    delta
    dust
    eza
    fzf
    gum
    hyperfine
    hyprland
    rustup
    shellcheck
    shfmt
    tailscale
    tealdeer
    tokei
    wl-clipboard
    xdg-desktop-portal
    xdg-desktop-portal-hyprland
    zoxide
  "
}

# ═══════════════════════════════════════════════════════════════════════════
# SECTION: logging.sh
# Verbosity normalization, the print() engine, and tagged helpers.
# ═══════════════════════════════════════════════════════════════════════════

initialize_logger() {
  # ── Verbosity Normalization ────────────────────────────────────────────
  # Scale: 0=quiet, 1=error, 2=warn, 3=info (default), 4=debug, 5=trace/verbose
  _verb_input="$(printf '%s' "${VERBOSITY:-3}" | tr '[:upper:]' '[:lower:]')"
  case ${_verb_input} in
  0 | quiet | silent | off) VERBOSITY=0 ;;
  1 | error | err) VERBOSITY=1 ;;
  2 | warn | warning) VERBOSITY=2 ;;
  3 | info | default | normal) VERBOSITY=3 ;;
  4 | debug) VERBOSITY=4 ;;
  5 | trace | verbose) VERBOSITY=5 ;;
  *) VERBOSITY=3 ;;
  esac
  export VERBOSITY

  # ── Core Printing Engine ────────────────────────────────────────────────
  if command -v gum >/dev/null 2>&1; then
    _has_gum=1
  else
    _has_gum=0
  fi

  print() {
    _lvl=3
    _name="info"
    _force=0
    _is_fatal=0

    while [ "$#" -gt 0 ]; do
      case "$1" in
      --force) _force=1 ;;
      --fatal)
        _lvl=1
        _name="fatal"
        _is_fatal=1
        ;;
      --error)
        _lvl=1
        _name="error"
        ;;
      --warn)
        _lvl=2
        _name="warn"
        ;;
      --info)
        _lvl=3
        _name="info"
        ;;
      --success)
        _lvl=3
        _name="success"
        ;;
      --markdown)
        _lvl=3
        _name="markdown"
        ;;
      --debug)
        _lvl=4
        _name="debug"
        ;;
      --verbose)
        _lvl=5
        _name="verbose"
        ;;
      --trace)
        _lvl=5
        _name="trace"
        ;;
      --)
        shift
        break
        ;;
      -*) ;;
      *) break ;;
      esac
      shift
    done

    # Dynamically resolve current VERBOSITY to prevent integer syntax errors
    _verb_local="$(printf '%s' "${VERBOSITY:-3}" | tr '[:upper:]' '[:lower:]')"
    case "${_verb_local}" in
    0 | quiet | silent | off) _verbosity=0 ;;
    1 | error) _verbosity=1 ;;
    2 | warn | warning) _verbosity=2 ;;
    3 | info | default | normal) _verbosity=3 ;;
    4 | debug) _verbosity=4 ;;
    5 | trace | verbose) _verbosity=5 ;;
    *)
      case "${_verb_local}" in
      '' | *[!0-9]*) _verbosity=3 ;;
      *) _verbosity="${_verb_local}" ;;
      esac
      ;;
    esac

    # Suppress message if VERBOSITY is too low, unless forced or fatal
    if
      [ "${_force}" -eq 0 ] &&
        [ "${_is_fatal}" -eq 0 ] &&
        [ "${_verbosity}" -lt "${_lvl}" ]
    then
      return 0
    fi

    if [ "${_has_gum}" -eq 1 ]; then
      case "${_name}" in
      fatal)
        gum log \
          --level fatal \
          --message.foreground="196" "$*"
        ;;
      error)
        gum log \
          --level error \
          --message.foreground="203" "$*"
        ;;
      warn)
        gum log \
          --level warn \
          --message.foreground="214" "$*"
        ;;
      info)
        gum log \
          --level info \
          --message.foreground="39" "$*"
        ;;
      success)
        gum log \
          --prefix="SUCCESS" \
          --prefix.foreground="82" \
          --message.foreground="82" "$*"
        ;;
        # --level info \
      debug)
        gum log \
          --level debug \
          --prefix.foreground="99" \
          --message.foreground="99" "$*"
        ;;
      trace)
        gum log \
          --level debug \
          --prefix="TRACE" \
          --prefix.foreground="242" \
          --message.foreground="242" "$*"
        ;;
      verbose)
        gum log \
          --level debug \
          --prefix="VERB" \
          --prefix.foreground="245" \
          --message.foreground="250" "$*"
        ;;
      markdown) printf "%s\n\n" "$*" | gum format ;;
      *) gum log "$*" ;;
      esac
    else
      case "${_name}" in
      fatal) printf "[  FATAL ] %s\n" "$*" >&2 ;;
      error) printf "[  ERROR ] %s\n" "$*" >&2 ;;
      warn) printf "[   WARN ] %s\n" "$*" ;;
      info) printf "[   INFO ] %s\n" "$*" ;;
      success) printf "[ SUCCESS] %s\n" "$*" ;;
      debug) printf "[  DEBUG ] %s\n" "$*" ;;
      trace | verbose) printf "[  TRACE ] %s\n" "$*" ;;
      markdown | *) printf "%s\n" "$*" ;;
      esac
    fi
  }

  # ── Tagged Helper API ────────────────────────────────────────────────────
  # Tagged status helpers bypass VERBOSITY checks
  print_fatal() { print --fatal "$*"; }
  print_error() { print --force --error "$*"; }
  print_warn() { print --force --warn "$*"; }
  print_info() { print --force --info "$*"; }
  print_success() { print --force --success "$*"; }
  print_markdown() { print --force --markdown "$*"; }
  print_debug() { print --force --debug "$*"; }
  print_verbose() { print --force --verbose "$*"; }
  print_trace() { print --force --trace "$*"; }
}

# ═══════════════════════════════════════════════════════════════════════════
# SECTION: bootstrap.sh
# binit + flake initialization for the current shell.
# ═══════════════════════════════════════════════════════════════════════════
initialize_bin() {
  BINIT_PATH="${DOTS_LIB_SH}/base/binit"
  BINIT_ACTION="--run"
  export BINIT_PATH BINIT_ACTION

  if [ -f "${BINIT_PATH}" ]; then :; else
    print --warn "binit not found at ${BINIT_PATH}"
  fi

  if [ -x "${BINIT_PATH}" ]; then :; else
    chmod -c +x "${BINIT_PATH}"
  fi

  # shellcheck disable=SC1090
  if . "${BINIT_PATH}"; then :; else
    print --error "Failed to initialize bin at ${BINIT_PATH}"
  fi
}

# ═══════════════════════════════════════════════════════════════════════════
# SECTION: paths.sh
# join_path / find_nix_profile_dir — generic path helpers with no
# dependency on anything else in this file.
# ═══════════════════════════════════════════════════════════════════════════

#? join_path base seg [seg ...] — join segments onto base with '/'
join_path() {
  _jp_out="$1"
  shift
  for _jp_seg in "$@"; do
    _jp_out="${_jp_out}/${_jp_seg}"
  done
  printf '%s\n' "${_jp_out}"
}

#? find_nix_profile_dir — pick the first usable nix profile tree.
#? NIX_USER_PROFILE_DIR (when set) points at the profile *generations*
#? store, not an activated tree with bin/lib/share, so it isn't usable
#? directly here. NIX_PROFILES is a space-separated priority list of
#? activated trees (system-wide, per-user, legacy symlink, etc.) — walk
#? it and return the first entry that actually has a bin/ directory.
#? Falls back to the legacy ~/.nix-profile symlink if nothing matched
#? or NIX_PROFILES is unset (non-NixOS systems, minimal shells, etc.).
find_nix_profile_dir() {
  for _fnp_dir in ${NIX_PROFILES:-}; do
    [ -d "${_fnp_dir}/bin" ] && printf '%s\n' "${_fnp_dir}" && return 0
  done
  printf '%s\n' "${HOME}/.nix-profile"
}

# ═══════════════════════════════════════════════════════════════════════════
# SECTION: timing.sh
# Single-shot stage timing (see: hyperfine isn't a fit for side-effecting,
# network-touching stages — this wraps one real run instead).
# ═══════════════════════════════════════════════════════════════════════════

# ── Timing Utility ─────────────────────────────────────────────────────────────
# ── Timing Utility ──────────────────────────────────────────────────────────
time_stage() {
  _stage_name="$1"
  shift

  _t0=$(date +%s.%N 2>/dev/null || date +%s)

  "$@"
  _stage_status=$?

  _t1=$(date +%s.%N 2>/dev/null || date +%s)
  _elapsed=$(
    awk \
      -v t0="${_t0}" \
      -v t1="${_t1}" \
      'BEGIN { printf "%.3fs", t1 - t0 }'
  )

  print --debug "${_stage_name} initialized in ${_elapsed}"
  return "${_stage_status}"
}

# ═══════════════════════════════════════════════════════════════════════════
# SECTION: packages_helpers.sh
# Package-name <-> binary-name mapping, additional-package diffing,
# and profile cleanup of packages now provided by the system.
# ═══════════════════════════════════════════════════════════════════════════

get_package_bin() {
  case "$1" in
  antigravity-cli) printf '%s\n' "agy" ;;
  antigravity-fhs) printf '%s\n' "antigravity" ;;
  gawk) printf '%s\n' "awk" ;;
  gnused) printf '%s\n' "sed" ;;
  hyprland) printf '%s\n' "hyprctl" ;;
  nodejs) printf '%s\n' "node" ;;
  wl-clipboard) printf '%s\n' "wl-copy" ;;
  xdg-desktop-portal) printf '%s\n' "xdg-desktop-portal" ;;
  xdg-desktop-portal-hyprland) printf '%s\n' "xdg-desktop-portal-hyprland" ;;
  zoxide) printf '%s\n' "z" ;;
  *) printf '%s\n' "$1" ;;
  esac
}

get_additional_packages() {
  for pkg in ${packages}; do
    case " ${dependencies_required} ${dependencies_optional} " in
    *" ${pkg} "*) ;;
    *) printf '%s\n' "${pkg}" ;;
    esac
  done
}

cleanup() {
  _profile_json="$(nix profile list --json 2>/dev/null)" || _profile_json=""

  # shellcheck disable=SC2086
  for pkg in $(get_additional_packages); do
    bin="$(get_package_bin "${pkg}")"
    bin_path="$(command -v "${bin}" 2>/dev/null)"
    case "${bin_path:-}" in
    /run/current-system/sw/bin/* | /etc/profiles/per-user/*/bin/*)
      case "${_profile_json}" in
      *\"${pkg}\":*)
        if nix profile remove "${pkg}" >/dev/null 2>&1; then
          print --info \
            "cleanup: removed ${pkg} (now provided by system)"
        else
          print --warn \
            "cleanup: failed to remove ${pkg} from the user profile"
        fi
        ;;
      *) ;;
      esac
      ;;
    *) ;;
    esac
  done
}

require_arg() {
  case "${2:-}" in
  "" | --*)
    print --error \
      "Flag '$1' requires an argument"
    return 1
    ;;
  *) ;;
  esac
}

# ═══════════════════════════════════════════════════════════════════════════
# SECTION: xdg_portals.sh
# xdg-open shim + XDG desktop portal restart/configure.
# ═══════════════════════════════════════════════════════════════════════════

setup_xdg_open() {
  mkdir -p "${XDG_BIN_HOME}"
  _xdg_open="$(join_path "${XDG_BIN_HOME}" xdg-open)"

  {
    printf '%s\n' '#!/usr/bin/env sh'
    printf '%s\n' 'exec gio open "$@"'
  } >"${_xdg_open}"

  chmod +x "${_xdg_open}"

  case ":${PATH}:" in
  *":${XDG_BIN_HOME}:"*) ;;
  *)
    PATH="${XDG_BIN_HOME}:${PATH}"
    export PATH
    ;;
  esac

  unset BROWSER
}

setup_portals() {
  case "${compositor:-}" in
  hyprland | niri | mango | cosmic) ;;
  *)
    print --info \
      "setup_portals: no supported compositor detected; skipping"
    return 0
    ;;
  esac

  #? Per-compositor portal backend package/binary + systemd unit name.
  case "${compositor}" in
  hyprland)
    _portal_backend_bin="xdg-desktop-portal-hyprland"
    _portal_backend_unit="xdg-desktop-portal-hyprland.service"
    _xdg_current_desktop="Hyprland"
    ;;
  niri)
    _portal_backend_bin="xdg-desktop-portal-gnome"
    _portal_backend_unit="xdg-desktop-portal-gnome.service"
    _xdg_current_desktop="niri"
    ;;
  mango)
    _portal_backend_bin="xdg-desktop-portal-wlr"
    _portal_backend_unit="xdg-desktop-portal-wlr.service"
    _xdg_current_desktop="wlroots"
    ;;
  cosmic)
    _portal_backend_bin="xdg-desktop-portal-cosmic"
    _portal_backend_unit="xdg-desktop-portal-cosmic.service"
    _xdg_current_desktop="COSMIC"
    ;;
  *) ;;
  esac

  print --info \
    "Restarting XDG desktop portals for ${compositor}..."

  XDG_DATA_DIRS="$(join_path "${NIX_PROFILE_DIR}" share):${XDG_DATA_DIRS}"
  XDG_CURRENT_DESKTOP="${_xdg_current_desktop}"
  export XDG_DATA_DIRS XDG_CURRENT_DESKTOP

  # Export variables to DBus activation environment
  if command -v dbus-update-activation-environment >/dev/null 2>&1; then
    dbus-update-activation-environment \
      --systemd \
      WAYLAND_DISPLAY \
      XDG_CURRENT_DESKTOP \
      XDG_DATA_DIRS \
      2>/dev/null || true
  fi

  # Prefer systemd user units if active
  if
    command -v systemctl >/dev/null 2>&1 &&
      systemctl --user \
        is-active \
        dbus \
        >/dev/null 2>&1
  then
    systemctl \
      --user \
      restart \
      "${_portal_backend_unit}" \
      xdg-desktop-portal.service \
      2>/dev/null || true
    print --success "Restarted XDG portals via systemd user units"
    return 0
  fi

  # Manual fallback with isolated file descriptors
  pkill -f xdg-desktop-portal 2>/dev/null || true

  _backend_portal="$(
    find \
      -L "${NIX_PROFILE_DIR}" \
      -name "${_portal_backend_bin}" \
      -type f -executable 2>/dev/null |
      head -n 1
  )"
  _portal_bin="$(
    find \
      -L "${NIX_PROFILE_DIR}" \
      -name "xdg-desktop-portal" \
      -type f -executable 2>/dev/null |
      head -n 1
  )"

  if [ -n "${_backend_portal}" ] && [ -n "${_portal_bin}" ]; then
    (exec "${_backend_portal}" >/dev/null 2>&1 </dev/null &)
    (exec "${_portal_bin}" -r >/dev/null 2>&1 </dev/null &)
    print --success \
      "Launched ${_portal_backend_bin} and main XDG desktop portal"
  else
    print --warn \
      "setup_portals: could not find portal executables in ${NIX_PROFILE_DIR}"
    return 1
  fi
}

# ═══════════════════════════════════════════════════════════════════════════
# SECTION: monitors.sh
# Compositor-agnostic monitor layout: detection, disabling, positioning,
# and per-compositor apply functions (hyprland/niri/mango).
# ═══════════════════════════════════════════════════════════════════════════

setup_monitors() {
  case "${monitor_pri_name:-}" in
  "")
    print --info \
      "setup_monitors: no monitors configured; skipping"
    return 0
    ;;
  *) ;;
  esac

  case "${compositor}" in
  none)
    print --info \
      "setup_monitors: no supported compositor detected (Hyprland, niri, or mango); skipping"
    return 0
    ;;
  *) ;;
  esac

  build_res() {
    printf '%sx%s@%s' "$1" "$2" "$3"
  }

  is_connected() {
    case "${1:-}" in "") return 1 ;; *) ;; esac
    case "${compositor}" in
    hyprland) hyprctl monitors all 2>/dev/null | rg -q "^Monitor $1" ;;
    niri) niri msg outputs 2>/dev/null | rg -q "Output.*$1" ;;
    mango) mmsg -O 2>/dev/null | rg -qx "$1" ;;
    *) return 1 ;;
    esac
  }

  force_disable() {
    case "${1:-}" in "") return 0 ;; *) ;; esac
    case "${compositor}" in
    hyprland) hyprctl keyword monitor "$1, disable" >/dev/null 2>&1 ;;
    niri) niri msg output "$1" off >/dev/null 2>&1 ;;
    mango) mmsg dispatch disable_monitor,"$1" >/dev/null 2>&1 ;;
    *) ;;
    esac
  }

  kernel_force_connector() {
    _kfc_name="${1:-}"
    case "${_kfc_name}" in "") return 1 ;; *) ;; esac

    _kfc_status=""
    for _p in /sys/class/drm/card*-"${_kfc_name}"/status; do
      [ -e "${_p}" ] && _kfc_status="${_p}" && break
    done
    case "${_kfc_status}" in
    "")
      print --warn \
        "kernel_force_connector: ${_kfc_name} not found under /sys/class/drm"
      return 1
      ;;
    *) ;;
    esac

    case "$(cat "${_kfc_status}" 2>/dev/null)" in
    connected) return 0 ;;
    *) ;;
    esac

    if ! sudo -n true 2>/dev/null; then
      print --warn \
        "kernel_force_connector: sudo password required; skipping kernel-level force for ${_kfc_name}"
      return 1
    fi

    _kfc_dir=""
    for _d in /sys/kernel/debug/dri/*/; do
      [ -d "${_d}${_kfc_name}" ] && _kfc_dir="${_d}${_kfc_name}" && break
    done
    case "${_kfc_dir}" in
    "")
      print --warn \
        "kernel_force_connector: no debugfs entry found for ${_kfc_name}"
      return 1
      ;;
    *) ;;
    esac

    sudo sh -c "echo on > '${_kfc_dir}/force'" 2>/dev/null
    sudo sh -c "echo 1 > '${_kfc_dir}/trigger_hotplug'" 2>/dev/null
    sleep 2

    case "$(cat "${_kfc_status}" 2>/dev/null)" in
    connected)
      print --success \
        "kernel_force_connector: ${_kfc_name} forced connected"
      return 0
      ;;
    *)
      print --warn \
        "kernel_force_connector: ${_kfc_name} still disconnected after force"
      return 1
      ;;
    esac
  }

  apply_disables() {
    case "${monitor_pri_disable:-0}" in
    1)
      if is_connected "${monitor_sec_name:-}" || is_connected "${monitor_ter_name:-}"; then
        force_disable "${monitor_pri_name}"
        monitor_pri_name=""
      else
        print --warn \
          "apply_disables: no fallback monitor detected; keeping ${monitor_pri_name} enabled"
      fi
      ;;
    *) ;;
    esac

    case "${monitor_sec_disable:-0}" in
    1)
      if is_connected "${monitor_pri_name:-}" || is_connected "${monitor_ter_name:-}"; then
        force_disable "${monitor_sec_name}"
        monitor_sec_name=""
      else
        print --warn \
          "apply_disables: no fallback monitor detected; keeping ${monitor_sec_name} enabled"
      fi
      ;;
    *) ;;
    esac

    case "${monitor_ter_disable:-0}" in
    1)
      if is_connected "${monitor_pri_name:-}" || is_connected "${monitor_sec_name:-}"; then
        force_disable "${monitor_ter_name}"
        monitor_ter_name=""
      else
        print --warn \
          "apply_disables: no fallback monitor detected; keeping ${monitor_ter_name} enabled"
      fi
      ;;
    *) ;;
    esac
  }

  calc_positions() {
    case "${monitor_sec_pos}" in
    left)
      monitor_sec_pos_xy="0x0"
      monitor_pri_pos_xy="${monitor_sec_width}x0"
      ;;
    right)
      monitor_pri_pos_xy="0x0"
      monitor_sec_pos_xy="${monitor_pri_width}x0"
      ;;
    top)
      monitor_pri_pos_xy="0x${monitor_sec_height}"
      monitor_sec_pos_xy="$(((monitor_pri_width - monitor_sec_width) / 2))x0"
      ;;
    bottom)
      monitor_pri_pos_xy="0x0"
      monitor_sec_pos_xy="0x${monitor_pri_height}"
      ;;
    mirror)
      monitor_pri_pos_xy="0x0"
      monitor_sec_pos_xy="auto"
      ;;
    *)
      print --error \
        "Unknown secondary monitor position: ${monitor_sec_pos}"
      return 1
      ;;
    esac

    case "${monitor_ter_name:-}" in
    "") ;;
    *)
      case "${monitor_ter_pos}" in
      left)
        monitor_ter_pos_xy="0x0"
        monitor_pri_pos_xy="${monitor_ter_width}x${monitor_pri_pos_xy#*x}"
        monitor_sec_pos_xy="${monitor_ter_width}x${monitor_sec_pos_xy#*x}"
        ;;
      right)
        monitor_ter_pos_xy="${monitor_pri_width}x0"
        ;;
      top)
        monitor_ter_pos_xy="0x0"
        monitor_pri_pos_xy="${monitor_pri_pos_xy%%x*}x${monitor_ter_height}"
        monitor_sec_pos_xy="${monitor_sec_pos_xy%%x*}x${monitor_ter_height}"
        ;;
      bottom)
        monitor_ter_pos_xy="0x${monitor_pri_height}"
        ;;
      *)
        print --error \
          "Unknown tertiary monitor position: ${monitor_ter_pos}"
        return 1
        ;;
      esac
      ;;
    esac
  }

  hyprland_apply() {
    _pri_res="$(
      build_res \
        "${monitor_pri_width}" \
        "${monitor_pri_height}" \
        "${monitor_pri_rate}"
    )"

    case "${monitor_sec_name:-}" in
    "")
      hyprctl keyword monitor \
        "${monitor_pri_name}, ${_pri_res}, ${monitor_pri_pos_xy}, 1" \
        >/dev/null
      return 0
      ;;
    *)
      _sec_res="$(
        build_res \
          "${monitor_sec_width}" \
          "${monitor_sec_height}" \
          "${monitor_sec_rate}"
      )"
      ;;
    esac

    case "${monitor_sec_pos}" in
    mirror)
      case "${monitor_ter_name:-}" in
      "") ;;
      *)
        print --error \
          "hyprland: tertiary monitor with monitor_sec_pos=mirror is not supported"
        return 1
        ;;
      esac
      hyprctl keyword monitor \
        "${monitor_pri_name}, ${_pri_res}, ${monitor_pri_pos_xy}, 1" \
        >/dev/null
      hyprctl keyword monitor \
        "${monitor_sec_name}, ${_sec_res}, auto, 1, mirror, ${monitor_pri_name}" \
        >/dev/null
      return 0
      ;;
    *) ;;
    esac

    _monitors="$(hyprctl monitors 2>/dev/null)" || _monitors=""
    _pri_current="$(printf '%s\n' "${_monitors}" |
      rg -N "Monitor ${monitor_pri_name}" -A 1 |
      rg 'at ' | awk '{print $3}')"
    _sec_current="$(printf '%s\n' "${_monitors}" |
      rg -N "Monitor ${monitor_sec_name}" -A 1 |
      rg 'at ' | awk '{print $3}')"

    _needs_reload=0
    case "${_pri_current}" in
    "${monitor_pri_pos_xy}") ;;
    *) _needs_reload=1 ;;
    esac
    case "${_sec_current}" in
    "${monitor_sec_pos_xy}") ;;
    *) _needs_reload=1 ;;
    esac

    case "${_needs_reload}" in
    1)
      hyprctl keyword monitor \
        "${monitor_pri_name}, ${_pri_res}, ${monitor_pri_pos_xy}, 1" \
        >/dev/null
      hyprctl keyword monitor \
        "${monitor_sec_name}, ${_sec_res}, ${monitor_sec_pos_xy}, 1" \
        >/dev/null
      case "${monitor_ter_name:-}" in
      "") ;;
      *)
        _ter_res="$(
          build_res \
            "${monitor_ter_width}" \
            "${monitor_ter_height}" \
            "${monitor_ter_rate}"
        )"
        hyprctl keyword monitor \
          "${monitor_ter_name}, ${_ter_res}, ${monitor_ter_pos_xy}, 1" \
          >/dev/null
        ;;
      esac
      ;;
    *) ;;
    esac
  }

  niri_get_pos() {
    niri msg outputs 2>/dev/null |
      rg -N "Output $1" -A 20 |
      rg -N '"logical":' -A 2 |
      rg -N '"x":' -A 1 |
      awk '
        BEGIN { x=""; y="" }
        /"x":/ { x=$2; gsub(/[,]/, "", x) }
        /"y":/ { y=$2; gsub(/[,]/, "", y); printf "%sx%s", x, y; exit }
      '
  }

  niri_apply() {
    _pri_res="$(
      build_res \
        "${monitor_pri_width}" \
        "${monitor_pri_height}" \
        "${monitor_pri_rate}"
    )"

    case "${monitor_sec_name:-}" in
    "")
      niri msg \
        output "${monitor_pri_name}" \
        mode "${_pri_res}" \
        position x="${monitor_pri_pos_xy%%x*}" y="${monitor_pri_pos_xy#*x}"
      return 0
      ;;
    *)
      _sec_res="$(
        build_res \
          "${monitor_sec_width}" \
          "${monitor_sec_height}" \
          "${monitor_sec_rate}"
      )"
      ;;
    esac

    case "${monitor_sec_pos}" in
    mirror)
      print --warn \
        "niri: output mirroring is not supported; configuring primary only"
      niri msg \
        output "${monitor_pri_name}" \
        mode "${_pri_res}" \
        position x="${monitor_pri_pos_xy%%x*}" y="${monitor_pri_pos_xy#*x}"
      return 0
      ;;
    *) ;;
    esac

    _pri_current="$(niri_get_pos "${monitor_pri_name}")" || _pri_current=""
    _sec_current="$(niri_get_pos "${monitor_sec_name}")" || _sec_current=""

    _needs_reload=0
    case "${_pri_current}" in
    "${monitor_pri_pos_xy}") ;;
    *) _needs_reload=1 ;;
    esac
    case "${_sec_current}" in
    "${monitor_sec_pos_xy}") ;;
    *) _needs_reload=1 ;;
    esac

    case "${_needs_reload}" in
    1)
      niri msg output "${monitor_pri_name}" \
        mode "${_pri_res}" \
        position x="${monitor_pri_pos_xy%%x*}" y="${monitor_pri_pos_xy#*x}"

      niri msg output "${monitor_sec_name}" \
        mode "${_sec_res}" \
        position x="${monitor_sec_pos_xy%%x*}" y="${monitor_sec_pos_xy#*x}"

      case "${monitor_ter_name:-}" in
      "") ;;
      *)
        _ter_res="$(build_res "${monitor_ter_width}" "${monitor_ter_height}" "${monitor_ter_rate}")"
        niri msg output "${monitor_ter_name}" \
          mode "${_ter_res}" \
          position x="${monitor_ter_pos_xy%%x*}" y="${monitor_ter_pos_xy#*x}"
        ;;
      esac
      ;;
    *) ;;
    esac
  }

  mango_apply() {
    #? Mango has no live per-monitor IPC call for mode/position — layout
    #? is declarative: a monitorrule= line per output in a config file,
    #? applied via reload_config. We own a dedicated include file so we
    #? never touch the user's hand-maintained config.conf directly.
    _mango_conf_dir="$(join_path "${XDG_CONFIG_HOME}" mango)"
    _mango_conf="$(join_path "${_mango_conf_dir}" config.conf)"
    _mango_monitors_conf="$(join_path "${_mango_conf_dir}" monitors.conf)"
    mkdir -p "${_mango_conf_dir}"

    #? Ensure config.conf sources our managed file — append once, idempotently.
    if [ -f "${_mango_conf}" ]; then
      rg -qF "source=${_mango_monitors_conf}" "${_mango_conf}" 2>/dev/null ||
        printf '\nsource=%s\n' "${_mango_monitors_conf}" >>"${_mango_conf}"
    else
      printf 'source=%s\n' "${_mango_monitors_conf}" >"${_mango_conf}"
    fi

    case "${monitor_sec_pos}" in
    mirror)
      case "${monitor_ter_name:-}" in
      "") ;;
      *)
        print --error "mango: tertiary monitor with monitor_sec_pos=mirror is not supported"
        return 1
        ;;
      esac
      print --warn "mango: output mirroring is not supported; configuring primary only"
      {
        printf 'monitorrule=name:%s,width:%s,height:%s,refresh:%s,x:%s,y:%s\n' \
          "${monitor_pri_name}" "${monitor_pri_width}" "${monitor_pri_height}" \
          "${monitor_pri_rate}" "${monitor_pri_pos_xy%%x*}" "${monitor_pri_pos_xy#*x}"
      } >"${_mango_monitors_conf}"
      mmsg dispatch reload_config >/dev/null 2>&1
      return 0
      ;;
    *) ;;
    esac

    {
      printf 'monitorrule=name:%s,width:%s,height:%s,refresh:%s,x:%s,y:%s\n' \
        "${monitor_pri_name}" "${monitor_pri_width}" "${monitor_pri_height}" \
        "${monitor_pri_rate}" "${monitor_pri_pos_xy%%x*}" "${monitor_pri_pos_xy#*x}"

      case "${monitor_sec_name:-}" in
      "") ;;
      *)
        printf 'monitorrule=name:%s,width:%s,height:%s,refresh:%s,x:%s,y:%s\n' \
          "${monitor_sec_name}" "${monitor_sec_width}" "${monitor_sec_height}" \
          "${monitor_sec_rate}" "${monitor_sec_pos_xy%%x*}" "${monitor_sec_pos_xy#*x}"
        ;;
      esac

      case "${monitor_ter_name:-}" in
      "") ;;
      *)
        printf 'monitorrule=name:%s,width:%s,height:%s,refresh:%s,x:%s,y:%s\n' \
          "${monitor_ter_name}" "${monitor_ter_width}" "${monitor_ter_height}" \
          "${monitor_ter_rate}" "${monitor_ter_pos_xy%%x*}" "${monitor_ter_pos_xy#*x}"
        ;;
      esac
    } >"${_mango_monitors_conf}"

    mmsg dispatch reload_config >/dev/null 2>&1
  }

  apply_monitor_states() {
    case "${monitor_pri_disable:-0}" in 1) ;; *) kernel_force_connector "${monitor_pri_name:-}" ;; esac
    case "${monitor_sec_disable:-0}" in 1) ;; *) kernel_force_connector "${monitor_sec_name:-}" ;; esac
    case "${monitor_ter_disable:-0}" in 1) ;; *) kernel_force_connector "${monitor_ter_name:-}" ;; esac
    apply_disables
  }

  apply_monitor_states
  calc_positions || return 1

  case "${compositor}" in
  hyprland) hyprland_apply ;;
  niri) niri_apply ;;
  mango) mango_apply ;;
  *) print --error "Unknown compositor: ${compositor}" ;;
  esac
}

# ═══════════════════════════════════════════════════════════════════════════
# SECTION: tailscale.sh
# Install, daemon bring-up (systemd or manual fallback), and connect.
# ═══════════════════════════════════════════════════════════════════════════

setup_tailscale() {
  install() {
    case "$(command -v tailscale 2>/dev/null)" in
    "")
      print --info "Installing Tailscale from nixpkgs..."
      nix profile add nixpkgs#tailscale || return 1
      ;;
    *) ;;
    esac
  }

  daemon_ready() {
    tailscale status >/dev/null 2>&1
  }

  start_systemd() {
    if ! command -v systemctl >/dev/null 2>&1; then
      return 1
    fi

    sudo systemctl set-environment PORT=0 FLAGS= >/dev/null 2>&1 || return 1
    sudo systemctl reset-failed tailscaled.service >/dev/null 2>&1 || true

    if ! sudo systemctl start tailscaled.service >/dev/null 2>&1; then
      return 1
    fi

    sleep 1
    daemon_ready
  }

  start_manual() {
    if pgrep -x tailscaled >/dev/null 2>&1; then
      return 0
    fi

    mkdir -p "${HOME}/.cache/tailscale"
    sudo tailscaled \
      --state=/var/lib/tailscale/tailscaled.state \
      --socket=/run/tailscale/tailscaled.sock \
      --port=0 \
      >/dev/null 2>&1 &
    # sudo tailscaled \
    #   --state=/var/lib/tailscale/tailscaled.state \
    #   --socket=/run/tailscale/tailscaled.sock \
    #   --port=0 \
    #   >"${HOME}/.cache/tailscale/tailscaled.log" 2>&1 &

    _i=0
    while [ "${_i}" -lt 20 ]; do
      daemon_ready && return 0
      sleep 0.25
      _i=$((_i + 1))
    done

    print --error "Tailscale daemon did not become ready; see ${HOME}/.cache/tailscale/tailscaled.log"
    return 1
  }

  connect() {
    if ! daemon_ready; then
      print --error "Tailscale daemon is not responding"
      return 1
    fi

    if ! tailscale status >/dev/null 2>&1; then
      sudo tailscale up
      return
    fi
    print --verbose "Tailscale already connected"
  }

  install || return 1

  if ! daemon_ready; then
    if ! start_systemd; then
      print --warn "systemd tailscaled service unavailable; using manual daemon fallback"
      start_manual || return 1
    fi
  fi

  connect
}

fix_net() {
  sudo tailscale down 2>/dev/null || true
  sudo pkill tailscaled 2>/dev/null || true

  _iface="$(ip route 2>/dev/null | rg default | awk '{ print $5; exit }')" || _iface=""
  case "${_iface}" in "") ;; *)
    sudo resolvectl revert "${_iface}" 2>/dev/null || true
    ;;
  esac

  sudo resolvectl flush-caches 2>/dev/null || true

  print --success "Stopped Tailscale and reset DNS for the default interface"
}

# ═══════════════════════════════════════════════════════════════════════════
# SECTION: darkman.sh
# Portal preference config + light/dark GTK theme transition hooks.
# ═══════════════════════════════════════════════════════════════════════════

setup_darkman() {
  print --info "Setting up Darkman portal configurations and hooks..."

  _portal_conf_dir="$(join_path "${XDG_CONFIG_HOME}" xdg-desktop-portal)"
  _dark_hook_dir="$(join_path "${XDG_DATA_HOME}" dark-mode.d)"
  _light_hook_dir="$(join_path "${XDG_DATA_HOME}" light-mode.d)"

  # 1. Portals configuration
  mkdir -p "${_portal_conf_dir}"
  {
    printf '%s\n' '[preferred]'
    printf '%s\n' 'default=gtk'
    printf '%s\n' 'org.freedesktop.impl.portal.OpenURI=gtk'
    printf '%s\n' 'org.freedesktop.impl.portal.Settings=darkman'
  } >"$(join_path "${_portal_conf_dir}" portals.conf)"

  # 2. Write transition hook scripts
  mkdir -p "${_dark_hook_dir}" "${_light_hook_dir}"

  {
    printf '%s\n' '#!/usr/bin/env sh'
    printf '%s\n' \
      "gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'"
    printf '%s\n' \
      "gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'"
  } >"$(join_path "${_dark_hook_dir}" gtk-theme.sh)"

  {
    printf '%s\n' '#!/usr/bin/env sh'
    printf '%s\n' \
      "gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'"
    printf '%s\n' \
      "gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita'"
  } >"$(join_path "${_light_hook_dir}" gtk-theme.sh)"

  chmod +x \
    "$(join_path "${_dark_hook_dir}" gtk-theme.sh)" \
    "$(join_path "${_light_hook_dir}" gtk-theme.sh)"

  # 3. Export session environment to DBus/Systemd
  if [ -n "${WAYLAND_DISPLAY:-}" ] || [ -n "${DISPLAY:-}" ]; then
    dbus-update-activation-environment \
      --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP DISPLAY 2>/dev/null || true
  fi

  # 4. Enable and restart darkman service if systemctl is available
  if command -v systemctl >/dev/null 2>&1; then
    systemctl --user enable darkman.service 2>/dev/null || true
    systemctl --user restart darkman.service 2>/dev/null || true
  fi

  print --success "Darkman hooks and portal routing applied"
}

# ═══════════════════════════════════════════════════════════════════════════
# SECTION: lorri.sh
# Install lorri if missing and ensure the user systemd socket-activated
# daemon is enabled and running.
# ═══════════════════════════════════════════════════════════════════════════

setup_lorri() {
  install() {
    case "$(command -v lorri 2>/dev/null)" in
    "")
      print --info "Installing lorri from nixpkgs..."
      NIXPKGS_ALLOW_UNFREE=1 nix profile add --impure "nixpkgs#lorri" || return 1
      ;;
    *) ;;
    esac
  }

  write_units() {
    _unit_dir="$(join_path "${XDG_CONFIG_HOME}" systemd user)"
    mkdir -p "${_unit_dir}"

    _lorri_bin="$(command -v lorri 2>/dev/null)"
    case "${_lorri_bin}" in
    "")
      print --error "setup_lorri: lorri binary not found after install"
      return 1
      ;;
    *) ;;
    esac

    # Socket unit (socket-activated)
    {
      printf '%s\n' '[Unit]'
      printf '%s\n' 'Description=Socket for Lorri Daemon'
      printf '%s\n' ''
      printf '%s\n' '[Socket]'
      printf '%s\n' 'ListenStream=%t/lorri/daemon.socket'
      printf '%s\n' 'RuntimeDirectory=lorri'
      printf '%s\n' ''
      printf '%s\n' '[Install]'
      printf '%s\n' 'WantedBy=sockets.target'
    } >"$(join_path "${_unit_dir}" lorri.socket)"

    # Service unit — resolved binary + a PATH that includes nix/git/tar.
    # systemd user units do not inherit the login PATH, so without this
    # the daemon starts but never evaluates (no `nix` on PATH).
    _lorri_path="$(join_path "${NIX_PROFILE_DIR}" bin):/run/current-system/sw/bin:${HOME}/.nix-profile/bin:/etc/profiles/per-user/${USER:-$(id -un)}/bin:/usr/bin:/bin"
    {
      printf '%s\n' '[Unit]'
      printf '%s\n' 'Description=Lorri Daemon'
      printf '%s\n' 'Requires=lorri.socket'
      printf '%s\n' 'After=lorri.socket'
      printf '%s\n' ''
      printf '%s\n' '[Service]'
      printf '%s\n' "ExecStart=${_lorri_bin} daemon"
      printf '%s\n' "Environment=PATH=${_lorri_path}"
      printf '%s\n' 'PrivateTmp=true'
      printf '%s\n' 'Restart=on-failure'
    } >"$(join_path "${_unit_dir}" lorri.service)"
  }

  enable_and_start() {
    if ! command -v systemctl >/dev/null 2>&1; then
      print --warn "setup_lorri: systemctl not available; start with: lorri daemon"
      return 1
    fi

    systemctl --user daemon-reload 2>/dev/null || true

    if systemctl --user is-enabled lorri.socket >/dev/null 2>&1; then
      print --verbose "lorri.socket already enabled"
    else
      systemctl --user enable lorri.socket >/dev/null 2>&1 || {
        print --warn "setup_lorri: failed to enable lorri.socket"
        return 1
      }
    fi

    # Start the socket (daemon starts on first client connection)
    if systemctl --user is-active lorri.socket >/dev/null 2>&1; then
      print --verbose "lorri.socket already active"
    else
      systemctl --user start lorri.socket >/dev/null 2>&1 || {
        print --warn "setup_lorri: failed to start lorri.socket"
        return 1
      }
    fi

    # Start (or restart) so a rewritten unit/PATH is picked up.
    systemctl --user daemon-reload 2>/dev/null || true
    systemctl --user restart lorri.service >/dev/null 2>&1 || \
      systemctl --user start lorri.service >/dev/null 2>&1 || true

    if systemctl --user is-active lorri.socket >/dev/null 2>&1; then
      print --success "lorri daemon (socket-activated) is enabled and running"
    else
      print --warn "setup_lorri: lorri.socket is not active after start attempt"
      return 1
    fi

    if systemctl --user is-active lorri.service >/dev/null 2>&1; then
      print --verbose "lorri.service is active"
    else
      print --warn "lorri.service is not active; check: journalctl --user -u lorri.service"
    fi
  }

  # Register this directory so the daemon starts the first evaluation.
  # `lorri watch` is a one-shot ping (not a long-running foreground process).
  watch_project() {
    if [ ! -f flake.nix ] && [ ! -f shell.nix ] && [ ! -f default.nix ]; then
      print --verbose "lorri: no flake.nix/shell.nix/default.nix here; skip watch"
      return 0
    fi

    if lorri watch >/dev/null 2>&1; then
      print --info "lorri: registered $(pwd -P) for background evaluation"
    else
      print --warn "lorri: failed to register this project with the daemon"
      return 1
    fi
  }

  install || return 1
  write_units || return 1
  enable_and_start || return 1
  watch_project
}

# ═══════════════════════════════════════════════════════════════════════════
# SECTION: utilities.sh
# Bulk install of missing optional/additional packages via nix profile.
# ═══════════════════════════════════════════════════════════════════════════

setup_utilities() {
  PATH="$(join_path "${NIX_PROFILE_DIR}" bin):${PATH}"
  export PATH

  _profile_list="$(nix profile list 2>/dev/null)" || _profile_list=""

  # shellcheck disable=SC2086
  for pkg in $(get_additional_packages); do
    bin="$(get_package_bin "${pkg}")"
    case "$(command -v "${bin}" 2>/dev/null)" in
    "")
      case "${_profile_list}" in
      *"${pkg}"*) ;;
      *) NIXPKGS_ALLOW_UNFREE=1 nix profile add --impure "nixpkgs#${pkg}" 2>/dev/null || true ;;
      esac
      ;;
    *) ;;
    esac
  done
}

# ═══════════════════════════════════════════════════════════════════════════
# SECTION: clipboard.sh
# Interactive clip() helper for copying file contents to the clipboard.
# ═══════════════════════════════════════════════════════════════════════════

clip() {
  no_ignore=0
  no_recurse=0
  clip_paths=""

  while [ $# -gt 0 ]; do
    case "$1" in
    --no-ignore) no_ignore=1 ;;
    --no-recurse) no_recurse=1 ;;
    *) clip_paths="${clip_paths:+${clip_paths} }$1" ;;
    esac
    shift
  done

  [ -z "${clip_paths}" ] && clip_paths="."

  collect_files() {
    target="$1"

    case "${target}" in
    /*) ;;
    *)
      if [ -e "${HOME}/${target}" ]; then
        target="${HOME}/${target}"
      elif [ -e "./${target}" ]; then
        target="./${target}"
      fi
      ;;
    esac

    if [ -f "${target}" ]; then
      gum confirm "Include ${target}?" </dev/tty >/dev/tty 2>&1
      exit_code=$?
      case "${exit_code}" in
      0) printf "%s\n" "${target}" ;;
      130)
        print --warn "clip: cancelled"
        return 1
        ;;
      *) ;;
      esac

    elif [ -d "${target}" ]; then
      choice="$(gum choose \
        --header "Directory: ${target}" \
        "all" "recurse" "skip" \
        </dev/tty)"
      exit_code=$?
      case "${exit_code:-0}" in
      130)
        print --warn "clip: cancelled"
        return 1
        ;;
      *) ;;
      esac

      case "${choice}" in
      all)
        fd_args="--type file --hidden"
        case "${no_recurse}" in
        1) fd_args="${fd_args} --max-depth 1" ;;
        *) ;;
        esac
        case "${no_ignore}" in
        1) fd_args="${fd_args} --no-ignore" ;;
        *) ;;
        esac
        # shellcheck disable=SC2086
        fd ${fd_args} . "${target}"
        ;;
      recurse)
        fd_args="--hidden --max-depth 1"
        case "${no_ignore}" in
        1) fd_args="${fd_args} --no-ignore" ;;
        *) ;;
        esac
        _recurse_tmp="$(mktemp)"
        # shellcheck disable=SC2086
        fd ${fd_args} . "${target}" >"${_recurse_tmp}"
        while IFS= read -r item; do
          case "${no_recurse}" in
          1)
            if [ -d "${item}" ]; then
              continue
            fi
            ;;
          *) ;;
          esac
          collect_files "${item}"
        done <"${_recurse_tmp}"
        rm -f "${_recurse_tmp}"
        ;;
      skip | *) ;;
      esac

    else
      print --error "clip: not found: ${target}"
    fi
  }

  selected=""
  _collect_tmp="$(mktemp)"
  # shellcheck disable=SC2086
  for clip_path in ${clip_paths}; do
    collect_files "${clip_path}" >>"${_collect_tmp}"
  done

  while IFS= read -r file; do
    selected="$(printf "%s\n%s" "${selected}" "${file}")"
  done <"${_collect_tmp}"
  rm -f "${_collect_tmp}"

  selected="$(printf "%s" "${selected}" | sed '/^$/d')"

  case "${selected}" in
  "")
    print --error "clip: nothing selected"
    return 1
    ;;
  *) ;;
  esac

  file_count="$(printf "%s\n" "${selected}" | wc -l | tr -d ' ')"
  print --info "clip: Building content from ${file_count} file(s)..."

  content=""
  _content_tmp="$(mktemp)"
  printf "%s\n" "${selected}" >"${_content_tmp}"

  while IFS= read -r file; do
    print --verbose "clip: adding ${file}"
    file_content="$(cat "${file}")"
    # shellcheck disable=SC2016
    content="$(printf '%s```\n# %s\n%s\n```\n\n' \
      "${content}" "${file}" "${file_content}")"
  done <"${_content_tmp}"
  rm -f "${_content_tmp}"

  printf "%s" "${content}" | wl-copy
  print --info "clip: copied ${file_count} file(s) to clipboard"
}

# ═══════════════════════════════════════════════════════════════════════════
# SECTION: rust.sh
# ═══════════════════════════════════════════════════════════════════════════

setup_rust() {
  install() {
    case "$(command -v rustup 2>/dev/null)" in
    "")
      print --info "Installing rustup..."
      nix profile add "nixpkgs#rustup"
      ;;
    *) ;;
    esac
  }

  apply() {
    case "$(rustup toolchain list 2>/dev/null)" in
    *"stable"*) ;;
    *)
      print --info "Setting up stable toolchain..."
      rustup default stable
      rustup component add clippy rustfmt rust-analyzer
      ;;
    esac
  }

  install
  apply
}

# ═══════════════════════════════════════════════════════════════════════════
# SECTION: tmux.sh
# ═══════════════════════════════════════════════════════════════════════════

setup_tmux() {
  case "$(command -v tmux 2>/dev/null)" in
  "")
    print --info "Installing tmux..."
    nix profile add "nixpkgs#tmux"
    ;;
  *) ;;
  esac
}

# ═══════════════════════════════════════════════════════════════════════════
# SECTION: remote_dev.sh
# VS Code / Zed remote dev bootstrap (env wrapper, ld stub, node,
# VS Code server env, optional pre-download, sshd).
# ═══════════════════════════════════════════════════════════════════════════

setup_remote_dev() {
  # Enable on both Victus and QBX
  case "${host}" in
  Victus | QBX) ;;
  *)
    print --info "setup_remote_dev: host not configured for remote dev; skipping"
    return 0
    ;;
  esac

  print --info "Setting up Remote Dev (VS Code & Zed) on ${host}..."

  _vscode_bin_dir="$(join_path "${VSCODE_SERVER_DIR}" bin)"
  _zed_data_dir="$(join_path "${XDG_DATA_HOME}" zed)"

  # Create necessary base directories
  mkdir -p "${_vscode_bin_dir}" "${_zed_data_dir}" "${XDG_BIN_HOME}"

  # 1. Create /usr/bin/env wrapper if missing
  if [ ! -f /usr/bin/env ]; then
    print --info "Creating /usr/bin/env wrapper for NixOS..."
    sudo mkdir -p /usr/bin 2>/dev/null || true
    {
      printf '%s\n' '#!/bin/sh'
      printf '%s\n' 'exec /run/current-system/sw/bin/env "$@"'
    } | sudo tee /usr/bin/env >/dev/null
    sudo chmod +x /usr/bin/env
    print --success "Created /usr/bin/env"
  fi

  # 2. Dynamic linker stub for precompiled ELFs (/lib64/ld-linux-x86-64.so.2)
  if [ ! -f /lib64/ld-linux-x86-64.so.2 ]; then
    print --info "Creating /lib64/ld-linux-x86-64.so.2 stub..."
    _system_ld="$(find /run/current-system/sw/lib -maxdepth 1 -name "ld-linux-x86-64.so.*" 2>/dev/null | head -n 1)"
    if [ -n "${_system_ld}" ]; then
      sudo mkdir -p /lib64 2>/dev/null || true
      sudo ln -sf "${_system_ld}" /lib64/ld-linux-x86-64.so.2
      print --success "Linked /lib64/ld-linux-x86-64.so.2 -> ${_system_ld}"
    else
      print --warn "Could not locate system ld-linux.so loader"
    fi
  fi

  # 3. Ensure nodejs is available (required by VS Code)
  if ! command -v node >/dev/null 2>&1; then
    case "$(nix profile list 2>/dev/null)" in
    *nodejs*) ;;
    *)
      print --info "Installing nodejs..."
      nix profile add "nixpkgs#nodejs" 2>/dev/null || true
      ;;
    esac
  fi

  # 4. Environment setup for VS Code Server
  _nix_sw_libs="/run/current-system/sw/lib:$(join_path "${NIX_PROFILE_DIR}" lib)"
  _vscode_bin="$(join_path "${NIX_PROFILE_DIR}" bin):/run/current-system/sw/bin"
  _vscode_server_env="$(join_path "${VSCODE_SERVER_DIR}" env)"
  _vscode_server_setup="$(join_path "${VSCODE_SERVER_DIR}" server-env-setup)"

  #> Write environment declarations to the env file
  {
    printf '%s\n' '# VS Code Remote Server Environment for NixOS'
    printf '%s\n' "PATH=\"${_vscode_bin}:\${PATH}\""
    printf '%s\n' "LD_LIBRARY_PATH=\"${_nix_sw_libs}:\${LD_LIBRARY_PATH:-}\""
    printf '%s\n' "NIX_LD_LIBRARY_PATH=\"${_nix_sw_libs}:\${NIX_LD_LIBRARY_PATH:-}\""
    printf '%s\n' 'NODE_OPTIONS="--max-old-space-size=4096"'
  } >"${_vscode_server_setup}"

  #> Write the executable setup wrapper script
  {
    printf '%s\n' '#!/usr/bin/env sh'
    printf '%s\n' "export PATH=\"${_vscode_bin}:\${PATH}\""
    printf '%s\n' "export LD_LIBRARY_PATH=\"${_nix_sw_libs}:\${LD_LIBRARY_PATH:-}\""
    printf '%s\n' "export NIX_LD_LIBRARY_PATH=\"${_nix_sw_libs}:\${NIX_LD_LIBRARY_PATH:-}\""
  } >"${_vscode_server_setup}"
  chmod +x "${_vscode_server_setup}"

  # 5. Pre-download VS Code Server commit if supplied as argument
  case "${1:-}" in
  "") ;;
  *)
    _vscode_commit="$1"
    case "$(command -v wget 2>/dev/null)" in
    "") nix profile add "nixpkgs#wget" >/dev/null 2>&1 || true ;;
    *) ;;
    esac

    _vscode_commit_dir="$(join_path "${_vscode_bin_dir}" "${_vscode_commit}")"
    if [ ! -d "${_vscode_commit_dir}" ]; then
      print --info "Pre-downloading VS Code Server (${_vscode_commit})..."
      cd "${_vscode_bin_dir}" || return 1
      if wget -q "https://update.code.visualstudio.com/commit:${_vscode_commit}/server-linux-x64/stable" -O vscode-server-linux-x64.tar.gz; then
        tar -xzf vscode-server-linux-x64.tar.gz
        mv vscode-server-linux-x64 "${_vscode_commit}"
        rm -f vscode-server-linux-x64.tar.gz
        print --success "VS Code Server pre-downloaded"
      fi
      cd - >/dev/null || return 1
    fi
    ;;
  esac

  # 6. Ensure SSH service is enabled and running
  if ! systemctl is-active sshd >/dev/null 2>&1; then
    print --info "Starting sshd..."
    sudo systemctl enable sshd 2>/dev/null || true
    sudo systemctl start sshd 2>/dev/null || true
  fi

  print --success "Remote Dev environment ready on ${host}!"
}

# ═══════════════════════════════════════════════════════════════════════════
# SECTION: remote_helix.sh
# push_hx (sync Helix config to preci) + dev (attach/create tmux session
# on preci over SSH).
# ═══════════════════════════════════════════════════════════════════════════

push_hx() {
  case "$(command -v rsync 2>/dev/null)" in
  "")
    nix profile add "nixpkgs#rsync" >/dev/null 2>&1 || {
      print --error "push_hx: failed to install rsync"
      return 1
    }
    ;;
  *) ;;
  esac

  rsync -av --delete ~/.config/helix/ craole@preci:~/.config/helix/ || {
    print --error "push_hx: rsync failed"
    return 1
  }

  print --success "push_hx: synced Helix config to preci"
  case "$(command -v tmux 2>/dev/null)" in
  "") nix profile add "nixpkgs#tmux" >/dev/null 2>&1 ;;
  *) ;;
  esac
}

dev() {
  no_sync=0
  while [ $# -gt 0 ]; do
    case "$1" in
    -n | --no-sync) no_sync=1 ;;
    *)
      print --error "dev: unknown option: $1"
      return 1
      ;;
    esac
    shift
  done

  case "${no_sync}" in
  0) push_hx ;;
  *) ;;
  esac

  ssh craole@preci -t "tmux attach-session -t dots 2>/dev/null || tmux new-session -s dots"
}

# ═══════════════════════════════════════════════════════════════════════════
# SECTION: orchestrate.sh
# execute() dispatches on ${command}, timing each stage in the "all" path.
# ═══════════════════════════════════════════════════════════════════════════

execute() {
  time_stage cleanup cleanup

  run() {
    case "${command}" in
    bin) initialize_bin ;;
    monitors) setup_monitors ;;
    tailscale) setup_tailscale ;;
    utilities) setup_utilities ;;
    rust) setup_rust ;;
    tmux) setup_tmux ;;
    xdg) setup_xdg_open ;;
    portals) setup_portals ;;
    remote-dev) setup_remote_dev "${@}" ;;
    darkman) setup_darkman ;;
    lorri) setup_lorri ;;
    all)
      time_stage xdg setup_xdg_open
      time_stage portals setup_portals
      time_stage monitors setup_monitors
      time_stage tailscale setup_tailscale
      time_stage darkman setup_darkman
      time_stage lorri setup_lorri
      time_stage utilities setup_utilities
      time_stage remote-dev setup_remote_dev "${@}"
      time_stage rust setup_rust
      time_stage tmux setup_tmux
      ;;
    *) ;;
    esac
  }

  case "${verbosity}" in
  verbose)
    set -x
    run "${@}"
    set +x
    ;;
  dry | debug)
    printf "Would run: %s\n" "${command}"
    printf "  primary:    %s  %sx%s@%s\n" \
      "${monitor_pri_name}" "${monitor_pri_width}" "${monitor_pri_height}" "${monitor_pri_rate}"
    printf "  secondary:  %s  %sx%s@%s  pos=%s\n" \
      "${monitor_sec_name}" "${monitor_sec_width}" "${monitor_sec_height}" "${monitor_sec_rate}" "${monitor_sec_pos}"
    case "${monitor_ter_name:-}" in
    "") printf "  tertiary:   (disabled)\n" ;;
    *) printf "  tertiary:   %s  %sx%s@%s  pos=%s\n" \
      "${monitor_ter_name}" "${monitor_ter_width}" "${monitor_ter_height}" "${monitor_ter_rate}" "${monitor_ter_pos}" ;;
    esac
    ;;
  info) run ;;
  quiet) run >/dev/null ;;
  *) ;;
  esac
}

# ═══════════════════════════════════════════════════════════════════════════
# SECTION: args.sh
# Argument parsing (command selection, monitor overrides, verbosity flags).
# ═══════════════════════════════════════════════════════════════════════════

parse_arguments() {
  while [ $# -gt 0 ]; do
    case "$1" in
    monitors | tailscale | utilities | darkman | lorri | rust | tmux | xdg | portals | remote-dev | info | all) command="$1" "$@" ;;

    --monitor-pri-disable) monitor_pri_disable=1 ;;
    --monitor-pri-enable) monitor_pri_disable=0 ;;
    --monitor-pri-name)
      require_arg "$1" "$2" || return 1
      monitor_pri_name="$2"
      shift
      ;;
    --monitor-pri-width)
      require_arg "$1" "$2" || return 1
      monitor_pri_width="$2"
      shift
      ;;
    --monitor-pri-height)
      require_arg "$1" "$2" || return 1
      monitor_pri_height="$2"
      shift
      ;;
    --monitor-pri-rate)
      require_arg "$1" "$2" || return 1
      monitor_pri_rate="$2"
      shift
      ;;

    --monitor-sec-disable) monitor_sec_disable=1 ;;
    --monitor-sec-enable) monitor_sec_disable=0 ;;
    --monitor-sec-name)
      require_arg "$1" "$2" || return 1
      monitor_sec_name="$2"
      shift
      ;;
    --monitor-sec-width)
      require_arg "$1" "$2" || return 1
      monitor_sec_width="$2"
      shift
      ;;
    --monitor-sec-height)
      require_arg "$1" "$2" || return 1
      monitor_sec_height="$2"
      shift
      ;;
    --monitor-sec-rate)
      require_arg "$1" "$2" || return 1
      monitor_sec_rate="$2"
      shift
      ;;
    --monitor-sec-pos)
      require_arg "$1" "$2" || return 1
      monitor_sec_pos="$2"
      shift
      ;;

    --monitor-ter-disable) monitor_ter_disable=1 ;;
    --monitor-ter-enable) monitor_ter_disable=0 ;;
    --monitor-ter-name)
      require_arg "$1" "$2" || return 1
      monitor_ter_name="$2"
      shift
      ;;
    --monitor-ter-width)
      require_arg "$1" "$2" || return 1
      monitor_ter_width="$2"
      shift
      ;;
    --monitor-ter-height)
      require_arg "$1" "$2" || return 1
      monitor_ter_height="$2"
      shift
      ;;
    --monitor-ter-rate)
      require_arg "$1" "$2" || return 1
      monitor_ter_rate="$2"
      shift
      ;;
    --monitor-ter-pos)
      require_arg "$1" "$2" || return 1
      monitor_ter_pos="$2"
      shift
      ;;

    -q | --quiet) verbosity="quiet" ;;
    -d | --debug) verbosity="debug" ;;
    -v | --verbose) verbosity="verbose" ;;
    --dry-run) verbosity="dry" ;;

    -h | --help)
      help_requested=1
      ;;
    *)
      print --error "Unknown option: $1"
      show_info
      return 1
      ;;
    esac
    shift
  done
}

# ═══════════════════════════════════════════════════════════════════════════
# SECTION: info.sh
# Detection (compositor, monitors, tailscale, app status) and the
# show_info() help/status renderer.
# ═══════════════════════════════════════════════════════════════════════════

collect_info() {
  detect_compositor
  detect_monitors
  detect_tailscale_status
  show_app_status
}

detect_compositor() {
  case "${HYPRLAND_INSTANCE_SIGNATURE:-}" in
  ?*) compositor="hyprland" ;;
  *)
    case "${NIRI_SOCKET:-}" in
    ?*) compositor="niri" ;;
    *)
      case "${MANGO_INSTANCE_SIGNATURE:-}" in
      ?*) compositor="mango" ;;
      *)
        case "${XDG_CURRENT_DESKTOP:-}" in
        COSMIC) compositor="cosmic" ;;
        *) compositor="none" ;;
        esac
        ;;
      esac
      ;;
    esac
    ;;
  esac
}

detect_tailscale_status() {
  if ! command -v tailscale >/dev/null 2>&1; then
    tailscale_status="not installed"
  else
    if tailscale_output="$(tailscale status 2>&1)"; then
      tailscale_status="connected"
    else
      tailscale_status="disconnected"
    fi

    tailscale_details="$(
      printf '%s\n' "${tailscale_output:-(no status output)}" |
        sed 's/^/    /'
    )"
  fi
}

detect_monitors() {
  detected_monitors=""
  detected_monitor_signature=""
  configured_monitors=""
  configured_monitor_signature=""

  case "${compositor}" in
  hyprland)
    _monitor_data="$(hyprctl monitors all 2>/dev/null)"
    detected_monitors="$(printf '%s\n' "${_monitor_data}" | awk '
      function emit() {
        if (name == "") return
        if (state == "inactive") print "- " name " [disabled]"
        else print "- " name (mode == "" ? "" : ": " mode)
        name = ""
      }
      /^Monitor / { emit(); name = $2; state = "active"; mode = "" }
      /^\t[^:]+@[^ ]+ at / {
        mode = $1 " at " $3
        gsub(/@/, "\\@", mode)
      }
      /^\tdisabled: true/ { state = "inactive" }
      /^$/ { emit() }
      END { emit() }
    ')"
    detected_monitor_signature="$(printf '%s\n' "${_monitor_data}" | awk '
      function emit() {
        if (name != "" && active) print name " " mode " " pos
        name = ""
      }
      /^Monitor / { emit(); name = $2; active = 1; mode = ""; pos = "" }
      /^\t[^:]+@[^ ]+ at / {
        mode = $1
        sub(/\..*/, "", mode)
        pos = $3
      }
      /^\tdisabled: true/ { active = 0 }
      /^$/ { emit() }
      END { emit() }
    ')"
    ;;
  niri)
    detected_monitors="$(niri msg outputs 2>/dev/null | awk '
      /^Output / {
        name = $2
        gsub(/[():]/, "", name)
        print "- " name
      }
    ')"
    ;;
  mango)
    detected_monitors="$(mmsg -O 2>/dev/null | awk '{ print "- " $0 }')"
    ;;
  *) ;;
  esac

  case "${monitor_sec_pos}" in
  left)
    monitor_pri_pos_xy="${monitor_sec_width}x0"
    monitor_sec_pos_xy="0x0"
    ;;
  right)
    monitor_pri_pos_xy="0x0"
    monitor_sec_pos_xy="${monitor_pri_width}x0"
    ;;
  top)
    monitor_pri_pos_xy="0x${monitor_sec_height}"
    monitor_sec_pos_xy="$(((monitor_pri_width - monitor_sec_width) / 2))x0"
    ;;
  bottom)
    monitor_pri_pos_xy="0x0"
    monitor_sec_pos_xy="0x${monitor_pri_height}"
    ;;
  mirror)
    monitor_pri_pos_xy="0x0"
    monitor_sec_pos_xy="0x0"
    ;;
  *) ;;
  esac

  _pri_disabled=0
  case "${monitor_pri_disable:-0}" in
  1) _pri_disabled=1 ;;
  *)
    case "${monitor_pri_name:-}" in
    "") _pri_disabled=1 ;;
    *) ;;
    esac
    ;;
  esac

  case "${_pri_disabled}" in
  1)
    case "${monitor_pri_name:-}" in
    "") ;;
    *) configured_monitors="- Disabled: ${monitor_pri_name} ${monitor_pri_width}x${monitor_pri_height}@${monitor_pri_rate}" ;;
    esac
    ;;
  *)
    configured_monitors="- Primary: ${monitor_pri_name} ${monitor_pri_width}x${monitor_pri_height}@${monitor_pri_rate}"
    configured_monitor_signature="${monitor_pri_name} ${monitor_pri_width}x${monitor_pri_height}@${monitor_pri_rate} ${monitor_pri_pos_xy}"
    ;;
  esac

  _sec_disabled=0
  case "${monitor_sec_disable:-0}" in
  1) _sec_disabled=1 ;;
  *)
    case "${monitor_sec_name:-}" in
    "") _sec_disabled=1 ;;
    *) ;;
    esac
    ;;
  esac

  if [ "${_sec_disabled}" -eq 0 ]; then
    configured_monitors="${configured_monitors}${configured_monitors:+
}- Secondary: ${monitor_sec_name} ${monitor_sec_width}x${monitor_sec_height}@${monitor_sec_rate}${monitor_sec_pos:+ ${monitor_sec_pos}}"
    configured_monitor_signature="${configured_monitor_signature}${configured_monitor_signature:+
}${monitor_sec_name} ${monitor_sec_width}x${monitor_sec_height}@${monitor_sec_rate} ${monitor_sec_pos_xy}"
  elif [ -n "${monitor_sec_name:-}" ]; then
    configured_monitors="${configured_monitors}${configured_monitors:+
}- Disabled: ${monitor_sec_name} ${monitor_sec_width}x${monitor_sec_height}@${monitor_sec_rate}"
  fi

  _ter_disabled=0
  case "${monitor_ter_disable:-0}" in
  1) _ter_disabled=1 ;;
  *)
    case "${monitor_ter_name:-}" in
    "") _ter_disabled=1 ;;
    *) ;;
    esac
    ;;
  esac

  if [ "${_ter_disabled}" -eq 0 ]; then
    configured_monitors="${configured_monitors}${configured_monitors:+
}- Tertiary: ${monitor_ter_name} ${monitor_ter_width}x${monitor_ter_height}@${monitor_ter_rate}${monitor_ter_pos:+ ${monitor_ter_pos}}"
    configured_monitor_signature="${configured_monitor_signature}${configured_monitor_signature:+
}${monitor_ter_name} ${monitor_ter_width}x${monitor_ter_height}@${monitor_ter_rate} ${monitor_ter_pos_xy:-}"
  elif [ -n "${monitor_ter_name:-}" ]; then
    configured_monitors="${configured_monitors}${configured_monitors:+
}- Disabled: ${monitor_ter_name} ${monitor_ter_width}x${monitor_ter_height}@${monitor_ter_rate}"
  fi

  case "${detected_monitor_signature}" in
  "") configuration_details="${configured_monitors:-(none configured)}" ;;
  "${configured_monitor_signature}") configuration_details="${configured_monitors:-(none configured)}" ;;
  *) configuration_details="### Detected
${detected_monitors:-(none detected)}

### Intended
${configured_monitors:-(none configured)}" ;;
  esac
}

format_app_status() {
  _app_list="$1"
  for _dep in $(printf '%s\n' "${_app_list}" | tr ',' '\n'); do
    _bin="$(get_package_bin "${_dep}")"
    _bin_path="$(command -v "${_bin}" 2>/dev/null)"
    if [ -n "${_bin_path}" ]; then
      printf -- "- **%s**: \`%s\`\n" "${_dep}" "${_bin_path}"
    else
      printf -- '- **%s**: missing dependency\n' "${_dep}"
    fi
  done
}

show_app_status() {
  _required_app_details="$(format_app_status "${dependencies_required}")"
  _optional_app_details="$(format_app_status "${dependencies_optional}")"
  _additional_packages="$(get_additional_packages)"
  _additional_app_details="$(format_app_status "${_additional_packages}")"

  application_details="$(
    printf '## Required\n%s\n\n' "${_required_app_details:-(none configured)}"
    printf '## Optional\n%s\n\n' "${_optional_app_details:-(none configured)}"
    printf '## Additional\n%s' "${_additional_app_details:-(none configured)}"
  )"
}

show_info() {
  bt='`'
  _info="$(
    printf '_Usage_        %s. %s [COMMAND] [OPTIONS]%s\n' "${bt}" "${name}" "${bt}"
    printf '_Description_  %s\n' "${description}"
    printf '_Path_         %s\n' "${path}"
    printf '_Author_       %s\n' "${author}"
    printf '_Version_      %s\n' "${version}"
    printf '_Host_         %s\n' "${host}"
    printf '_Compositor_   %s\n' "${compositor}"
    printf '_Command_      %s\n' "${command}"
    printf '_Verbosity_    %s\n' "${verbosity}"
    printf '\n'

    printf '# APPLICATIONS\n%s\n\n' "${application_details:-(none configured)}"

    printf '# COMMANDS\n'
    printf '  **info**           Show script, runtime, and configuration information\n'
    printf '  **monitors**       Configure monitor layout (Hyprland, niri, mango)\n'
    printf '  **tailscale**      Install and connect Tailscale\n'
    printf '  **utilities**      Install utility tools\n'
    printf '  **rust**           Set up Rust toolchain\n'
    printf '  **tmux**           Install tmux\n'
    printf '  **portals**        Configure and restart XDG desktop portals\n'
    printf '  **darkman**        Configure Darkman theme hooks and portal settings\n'
    printf '  **lorri**          Install lorri and enable the socket-activated daemon\n'
    printf '  **remote-dev**     Configure VS Code & Zed Remote Dev (Victus & QBX)\n'
    printf '  **all**            Run all setup steps (default)\n'
    printf '\n'

    printf '# OPTIONS\n\n'
    printf '## GENERAL\n'
    printf '  %s-h, --help   %s            Show this help\n' "${bt}" "${bt}"
    printf '  %s-q, --quiet  %s            Suppress all output\n' "${bt}" "${bt}"
    printf '  %s-d, --debug  %s            Show detailed internal progress\n' "${bt}" "${bt}"
    printf '  %s-v, --verbose%s            Show all commands as they run\n' "${bt}" "${bt}"
    printf '  %s    --dry-run%s            Show what would be done without doing it\n' "${bt}" "${bt}"
    printf '\n'

    printf '## MONITOR\n'
    printf '  %s--monitor-{tag}-{flag}%s   Set monitor configuration\n' "${bt}" "${bt}"
    printf '\n'

    printf '### Tags\n'
    printf '  - **pri**        primary\n'
    printf '  - **sec**        secondary\n'
    printf '  - **ter**        tertiary\n'
    printf '\n'

    printf '### Flags\n'
    printf '  - **name**       an empty name disables the monitor\n'
    printf '  - **width**      horizontal resolution\n'
    printf '  - **height**     vertical resolution\n'
    printf '  - **rate**       refresh rate\n'
    printf '  - **pos**        placement can be left, right, top, bottom, or mirror\n'
    printf '  - **disable**    force this monitor off (e.g. --monitor-sec-disable)\n'
    printf '\n'

    printf '### Configuration\n%s\n\n' "${configuration_details}"

    printf '## TAILSCALE (%s)\n%s\n\n' "${tailscale_status}" "${tailscale_details}"

    printf '# NOTES\n'
    printf -- '- Defaults are host-specific, resolved via %shostname%s\n' "${bt}" "${bt}"
    printf -- '- DE/WM is auto-detected via session environment\n'
    printf -- '- When sourced exported variables persist in the parent shell: %s. %s%s\n' "${bt}" "${name}" "${bt}"
    printf -- '- When called as a subshell variables are lost: %s%s%s\n' "${bt}" "${name}" "${bt}"
  )"
  print --markdown "${_info}"
}

# ═══════════════════════════════════════════════════════════════════════════
# SECTION: main.sh
# Entry point — this is the only part that should stay in the top-level
# file once the sections above move out. It just sources/calls each stage
# in order, exactly as shown below.
# ═══════════════════════════════════════════════════════════════════════════

initialize_flake() {
  if [ ! -f flake.nix ] && [ ! -f shell.nix ] && [ ! -f default.nix ]; then
    return 0
  fi

  # direnv stdlib (`watch_file`, `use`) exists only while evaluating .envrc.
  # `lorri export direnv-adapter` emits watch_file — never eval it in a
  # normal shell (that is the `bash: watch_file: command not found` error).
  if [ -n "${DIRENV_IN_ENVRC:-}" ]; then
    case "${1:-}" in
    --impure)
      #TODO: This should be done in overlays, but it's not working right now
      NIXPKGS_ALLOW_UNFREE=1
      export NIXPKGS_ALLOW_UNFREE
      use flake . --no-pure-eval
      ;;
    *)
      if command -v lorri >/dev/null 2>&1; then
        # shellcheck disable=SC2312
        eval "$(lorri export direnv-adapter)"
      else
        use flake
      fi
      ;;
    esac
    return 0
  fi

  command -v lorri >/dev/null 2>&1 || return 0

  # Register with the daemon (no-op if already watched) then load the last
  # completed evaluation into this shell. Do not wait for the first build.
  lorri watch >/dev/null 2>&1 || true

  _lorri_env="$(lorri export bash 2>/dev/null)" || _lorri_env=""
  case "${_lorri_env}" in
  "")
    print --info \
      "lorri: no completed evaluation yet; daemon is building in the background"
    ;;
  *)
    # shellcheck disable=SC2312
    eval "${_lorri_env}"
    print --verbose "lorri: loaded cached evaluation into this shell"
    ;;
  esac
}

main() {
  configure || return 1
  initialize_logger
  configure_host_profile || return 1
  configure_packages
  parse_arguments "$@" || return 1

  time_stage environment collect_info || return 1

  case "${help_requested}:${command}" in
  1:* | *:info) show_info ;;
  *)
    execute
    # After the daemon is up so `lorri watch` / export can talk to it.
    time_stage flake initialize_flake
    ;;
  esac
}
main "$@"
