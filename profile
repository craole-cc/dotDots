#!/bin/sh
# shellcheck enable=all

# ── Configuration ─────────────────────────────────────────────────────────────

configure() {
  # ── Metadata ────────────────────────────────────────────────────────────
  name="profile"
  home="${DOTS:-${HOME}}"
  path="${home}/${name}"
  description="Temporary bootstrap for NixOS environment"
  author="craole"
  version="0.2.5"

  # ── Runtime ─────────────────────────────────────────────────────────────
  verbosity="info" #? Levels: quiet | info | verbose | debug | dry
  command="all"    #? The active command to run
  help_requested=0

  # ── Display ─────────────────────────────────────────────────────
  #? Detect gum once; shared by all print functions and print_format
  case "$(command -v gum 2>/dev/null)" in
  "")
    _has_gum=0
    ;;
  *)
    _has_gum=1
    ;;
  esac

  #? Internal dispatcher — not for direct use
  _print() {
    _p_level="$1"
    shift

    #> Validate level once — recurse as error if unknown
    case "${_p_level}" in
    debug | info | warn | error | success) ;;
    *)
      _print error "_print: unknown level '${_p_level}': $*"
      return
      ;;
    esac

    #> Dispatch to backend — invalid levels already handled above
    case "${_has_gum}" in
    1)
      case "${_p_level}" in
      debug) gum log --level debug --message.foreground="99" "$*" ;;
      info) gum log --level info "$*" ;;
      warn) gum log --level warn "$*" ;;
      error) gum log --level error "$*" ;;
      success) gum log --level info "$*" ;;
      *) ;;
      esac
      ;;
    *)
      case "${_p_level}" in
      debug) printf "debug: %s\n" "$*" ;;
      info) printf "info:  %s\n" "$*" ;;
      warn) printf "warn:  %s\n" "$*" ;;
      error) printf "error: %s\n" "$*" >&2 ;;
      success) printf "ok:    %s\n" "$*" ;;
      *) ;;
      esac
      ;;
    esac
  }

  print_error() { _print error "$*"; }
  print_warn() { case "${verbosity}" in quiet) ;; *) _print warn "$*" ;; esac }
  print_success() { case "${verbosity}" in quiet) ;; *) _print success "$*" ;; esac }
  print_info() { case "${verbosity}" in quiet) ;; *) _print info "$*" ;; esac }
  print_debug() { case "${verbosity}" in debug) _print debug "$*" ;; *) ;; esac }
  print_verbose() { case "${verbosity}" in verbose | debug) _print info "$*" ;; *) ;; esac }
  print_markdown() {
    case "${_has_gum}" in
    1) printf "%s\n\n" "$*" | gum format ;;
    *) printf "%s\n" "$*" ;;
    esac
  }

  # ── Host ───────────────────────────────────────────────────────
  host="$(hostname)" #? The current host
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
    print_error "Unknown monitor setup; define profile mappings"
    return 1
    ;;
  esac

  # ── Packages ──────────────────────────────────────────────────────
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
  dependencies_required="gawk gnused ripgrep fd sudo"
  dependencies_optional="bat bottom darkman delta dust eza fzf gum hyperfine hyprland rustup shellcheck shfmt tailscale tealdeer tokei wl-clipboard xdg-desktop-portal xdg-desktop-portal-hyprland zoxide"
}

# ── Helpers ───────────────────────────────────────────────────────────────────

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
          print_info "cleanup: removed ${pkg} (now provided by system)"
        else
          print_warn "cleanup: failed to remove ${pkg} from the user profile"
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
    print_error "Flag '$1' requires an argument"
    return 1
    ;;
  *) ;;
  esac
}

# ── XDG/OpenURI & Desktop Portals ─────────────────────────────────────────────

setup_xdg_open() {
  mkdir -p "${HOME}/.local/bin"

  {
    printf '%s\n' '#!/usr/bin/env sh'
    printf '%s\n' 'exec gio open "$@"'
  } >"${HOME}/.local/bin/xdg-open"

  chmod +x "${HOME}/.local/bin/xdg-open"

  case ":${PATH}:" in
  *":${HOME}/.local/bin:"*) ;;
  *)
    PATH="${HOME}/.local/bin:${PATH}"
    export PATH
    ;;
  esac

  unset BROWSER
}

setup_portals() {
  case "${compositor:-}" in
  hyprland) ;;
  *)
    print_info "setup_portals: compositor is not Hyprland; skipping"
    return 0
    ;;
  esac

  print_info "Restarting XDG desktop portals for Hyprland..."

  XDG_DATA_DIRS="${HOME}/.nix-profile/share:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
  export XDG_DATA_DIRS
  export XDG_CURRENT_DESKTOP=Hyprland

  # Export variables to DBus activation environment
  if command -v dbus-update-activation-environment >/dev/null 2>&1; then
    dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_DATA_DIRS 2>/dev/null || true
  fi

  # Prefer systemd user units if active
  if command -v systemctl >/dev/null 2>&1 && systemctl --user is-active dbus >/dev/null 2>&1; then
    systemctl --user restart xdg-desktop-portal-hyprland.service xdg-desktop-portal.service 2>/dev/null || true
    print_success "Restarted XDG portals via systemd user units"
    return 0
  fi

  # Manual fallback with isolated file descriptors
  pkill -f xdg-desktop-portal 2>/dev/null || true

  _hyprland_portal="$(find -L "${HOME}/.nix-profile" -name "xdg-desktop-portal-hyprland" -type f -executable 2>/dev/null | head -n 1)"
  _portal_bin="$(find -L "${HOME}/.nix-profile" -name "xdg-desktop-portal" -type f -executable 2>/dev/null | head -n 1)"

  if [ -n "${_hyprland_portal}" ] && [ -n "${_portal_bin}" ]; then
    (exec "${_hyprland_portal}" >/dev/null 2>&1 </dev/null &)
    (exec "${_portal_bin}" -r >/dev/null 2>&1 </dev/null &)
    print_success "Launched Hyprland portal and main XDG desktop portal"
  else
    print_warn "setup_portals: could not find portal executables in ~/.nix-profile"
    return 1
  fi
}

# ── Monitors ──────────────────────────────────────────────────────────────────

setup_monitors() {
  case "${monitor_pri_name:-}" in
  "")
    print_info "setup_monitors: no monitors configured; skipping"
    return 0
    ;;
  *) ;;
  esac

  case "${compositor}" in
  none)
    print_info "setup_monitors: no supported compositor detected (Hyprland or niri); skipping"
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
    *) return 1 ;;
    esac
  }

  force_disable() {
    case "${1:-}" in "") return 0 ;; *) ;; esac
    case "${compositor}" in
    hyprland) hyprctl keyword monitor "$1, disable" >/dev/null 2>&1 ;;
    niri) niri msg output "$1" off >/dev/null 2>&1 ;;
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
      print_warn "kernel_force_connector: ${_kfc_name} not found under /sys/class/drm"
      return 1
      ;;
    *) ;;
    esac

    case "$(cat "${_kfc_status}" 2>/dev/null)" in
    connected) return 0 ;;
    *) ;;
    esac

    if ! sudo -n true 2>/dev/null; then
      print_warn "kernel_force_connector: sudo needs a password; skipping kernel-level force for ${_kfc_name}"
      return 1
    fi

    _kfc_dir=""
    for _d in /sys/kernel/debug/dri/*/; do
      [ -d "${_d}${_kfc_name}" ] && _kfc_dir="${_d}${_kfc_name}" && break
    done
    case "${_kfc_dir}" in
    "")
      print_warn "kernel_force_connector: no debugfs entry found for ${_kfc_name}"
      return 1
      ;;
    *) ;;
    esac

    sudo sh -c "echo on > '${_kfc_dir}/force'" 2>/dev/null
    sudo sh -c "echo 1 > '${_kfc_dir}/trigger_hotplug'" 2>/dev/null
    sleep 2

    case "$(cat "${_kfc_status}" 2>/dev/null)" in
    connected)
      print_success "kernel_force_connector: ${_kfc_name} forced connected"
      return 0
      ;;
    *)
      print_warn "kernel_force_connector: ${_kfc_name} still disconnected after force"
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
        print_warn "apply_disables: no fallback monitor detected; keeping ${monitor_pri_name} enabled"
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
        print_warn "apply_disables: no fallback monitor detected; keeping ${monitor_sec_name} enabled"
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
        print_warn "apply_disables: no fallback monitor detected; keeping ${monitor_ter_name} enabled"
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
      print_error "Unknown secondary monitor position: ${monitor_sec_pos}"
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
        print_error "Unknown tertiary monitor position: ${monitor_ter_pos}"
        return 1
        ;;
      esac
      ;;
    esac
  }

  hyprland_apply() {
    _pri_res="$(build_res "${monitor_pri_width}" "${monitor_pri_height}" "${monitor_pri_rate}")"

    case "${monitor_sec_name:-}" in
    "")
      hyprctl keyword monitor "${monitor_pri_name}, ${_pri_res}, ${monitor_pri_pos_xy}, 1" >/dev/null
      return 0
      ;;
    *)
      _sec_res="$(build_res "${monitor_sec_width}" "${monitor_sec_height}" "${monitor_sec_rate}")"
      ;;
    esac

    case "${monitor_sec_pos}" in
    mirror)
      case "${monitor_ter_name:-}" in
      "") ;;
      *)
        print_error "hyprland: tertiary monitor with monitor_sec_pos=mirror is not supported"
        return 1
        ;;
      esac
      hyprctl keyword monitor "${monitor_pri_name}, ${_pri_res}, ${monitor_pri_pos_xy}, 1" >/dev/null
      hyprctl keyword monitor "${monitor_sec_name}, ${_sec_res}, auto, 1, mirror, ${monitor_pri_name}" >/dev/null
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
      hyprctl keyword monitor "${monitor_pri_name}, ${_pri_res}, ${monitor_pri_pos_xy}, 1" >/dev/null
      hyprctl keyword monitor "${monitor_sec_name}, ${_sec_res}, ${monitor_sec_pos_xy}, 1" >/dev/null
      case "${monitor_ter_name:-}" in
      "") ;;
      *)
        _ter_res="$(build_res "${monitor_ter_width}" "${monitor_ter_height}" "${monitor_ter_rate}")"
        hyprctl keyword monitor "${monitor_ter_name}, ${_ter_res}, ${monitor_ter_pos_xy}, 1" >/dev/null
        ;;
      esac
      ;;
    *) ;;
    esac
  }

  niri_get_pos() {
    niri msg outputs 2>/dev/null | rg -N "Output $1" -A 20 | rg -N '"logical":' -A 2 | rg -N '"x":' -A 1 | awk '
      BEGIN { x=""; y="" }
      /"x":/ { x=$2; gsub(/[,]/, "", x) }
      /"y":/ { y=$2; gsub(/[,]/, "", y); printf "%sx%s", x, y; exit }
    '
  }

  niri_apply() {
    _pri_res="$(build_res "${monitor_pri_width}" "${monitor_pri_height}" "${monitor_pri_rate}")"

    case "${monitor_sec_name:-}" in
    "")
      niri msg output "${monitor_pri_name}" \
        mode "${_pri_res}" \
        position x="${monitor_pri_pos_xy%%x*}" y="${monitor_pri_pos_xy#*x}"
      return 0
      ;;
    *)
      _sec_res="$(build_res "${monitor_sec_width}" "${monitor_sec_height}" "${monitor_sec_rate}")"
      ;;
    esac

    case "${monitor_sec_pos}" in
    mirror)
      print_warn "niri: output mirroring is not supported; configuring primary only"
      niri msg output "${monitor_pri_name}" \
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
  *) print_error "Unknown compositor: ${compositor}" ;;
  esac
}

# ── Tailscale ─────────────────────────────────────────────────────────────────

setup_tailscale() {
  install() {
    case "$(command -v tailscale 2>/dev/null)" in
    "")
      print_info "Installing Tailscale from nixpkgs..."
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
      >"${HOME}/.cache/tailscale/tailscaled.log" 2>&1 &

    _i=0
    while [ "${_i}" -lt 20 ]; do
      daemon_ready && return 0
      sleep 0.25
      _i=$((_i + 1))
    done

    print_error "Tailscale daemon did not become ready; see ${HOME}/.cache/tailscale/tailscaled.log"
    return 1
  }

  connect() {
    if ! daemon_ready; then
      print_error "Tailscale daemon is not responding"
      return 1
    fi

    if ! tailscale status >/dev/null 2>&1; then
      sudo tailscale up
      return
    fi
    print_verbose "Tailscale already connected"
  }

  install || return 1

  if ! daemon_ready; then
    if ! start_systemd; then
      print_warn "systemd tailscaled service unavailable; using manual daemon fallback"
      start_manual || return 1
    fi
  fi

  connect
}

# ── Utilities ─────────────────────────────────────────────────────────────────

setup_darkman() {
  print_info "Setting up Darkman portal configurations and hooks..."

  # 1. Portals configuration
  mkdir -p "${HOME}/.config/xdg-desktop-portal"
  {
    printf '%s\n' '[preferred]'
    printf '%s\n' 'default=gtk'
    printf '%s\n' 'org.freedesktop.impl.portal.OpenURI=gtk'
    printf '%s\n' 'org.freedesktop.impl.portal.Settings=darkman'
  } >"${HOME}/.config/xdg-desktop-portal/portals.conf"

  # 2. Write transition hook scripts
  mkdir -p \
    "${HOME}/.local/share/dark-mode.d" \
    "${HOME}/.local/share/light-mode.d"

  {
    printf '%s\n' '#!/usr/bin/env sh'
    printf '%s\n' \
      "gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'"
    printf '%s\n' \
      "gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'"
  } >"${HOME}/.local/share/dark-mode.d/gtk-theme.sh"

  {
    printf '%s\n' '#!/usr/bin/env sh'
    printf '%s\n' \
      "gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'"
    printf '%s\n' \
      "gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita'"
  } >"${HOME}/.local/share/light-mode.d/gtk-theme.sh"

  chmod +x \
    "${HOME}/.local/share/dark-mode.d/gtk-theme.sh" \
    "${HOME}/.local/share/light-mode.d/gtk-theme.sh"

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

  print_success "Darkman hooks and portal routing applied"
}

setup_utilities() {
  export PATH="${HOME}/.nix-profile/bin:${PATH}"
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

fix_net() {
  sudo tailscale down 2>/dev/null || true
  sudo pkill tailscaled 2>/dev/null || true

  _iface="$(ip route 2>/dev/null | rg default | awk '{ print $5; exit }')" || _iface=""
  case "${_iface}" in "") ;; *)
    sudo resolvectl revert "${_iface}" 2>/dev/null || true
    ;;
  esac

  sudo resolvectl flush-caches 2>/dev/null || true

  print_success "Stopped Tailscale and reset DNS for the default interface"
}

# ── Clipboard ─────────────────────────────────────────────────────────────────

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
        print_warn "clip: cancelled"
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
        print_warn "clip: cancelled"
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
      print_error "clip: not found: ${target}"
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
    print_error "clip: nothing selected"
    return 1
    ;;
  *) ;;
  esac

  file_count="$(printf "%s\n" "${selected}" | wc -l | tr -d ' ')"
  print_info "clip: Building content from ${file_count} file(s)..."

  content=""
  _content_tmp="$(mktemp)"
  printf "%s\n" "${selected}" >"${_content_tmp}"

  while IFS= read -r file; do
    print_verbose "clip: adding ${file}"
    file_content="$(cat "${file}")"
    # shellcheck disable=SC2016
    content="$(printf '%s```\n# %s\n%s\n```\n\n' \
      "${content}" "${file}" "${file_content}")"
  done <"${_content_tmp}"
  rm -f "${_content_tmp}"

  printf "%s" "${content}" | wl-copy
  print_info "clip: copied ${file_count} file(s) to clipboard"
}

# ── Rust ──────────────────────────────────────────────────────────────────────

setup_rust() {
  install() {
    case "$(command -v rustup 2>/dev/null)" in
    "")
      print_info "Installing rustup..."
      nix profile add "nixpkgs#rustup"
      ;;
    *) ;;
    esac
  }

  apply() {
    case "$(rustup toolchain list 2>/dev/null)" in
    *"stable"*) ;;
    *)
      print_info "Setting up stable toolchain..."
      rustup default stable
      rustup component add clippy rustfmt rust-analyzer
      ;;
    esac
  }

  install
  apply
}

# ── Tmux ──────────────────────────────────────────────────────────────────────

setup_tmux() {
  case "$(command -v tmux 2>/dev/null)" in
  "")
    print_info "Installing tmux..."
    nix profile add "nixpkgs#tmux"
    ;;
  *) ;;
  esac
}

# ── Remote Code Server ────────────────────────────────────────────────────────

setup_remote_dev() {
  # Enable on both Victus and QBX
  case "$(hostname)" in
  Victus | QBX) ;;
  *)
    print_info "setup_remote_dev: host not configured for remote dev; skipping"
    return 0
    ;;
  esac

  print_info "Setting up Remote Dev (VS Code & Zed) on $(hostname)..."

  # Create necessary base directories
  mkdir -p "${HOME}/.vscode-server/bin"
  mkdir -p "${HOME}/.local/share/zed"
  mkdir -p "${HOME}/.local/bin"

  # 1. Create /usr/bin/env wrapper if missing
  if [ ! -f /usr/bin/env ]; then
    print_info "Creating /usr/bin/env wrapper for NixOS..."
    sudo mkdir -p /usr/bin 2>/dev/null || true
    {
      printf '%s\n' '#!/bin/sh'
      printf '%s\n' 'exec /run/current-system/sw/bin/env "$@"'
    } | sudo tee /usr/bin/env >/dev/null
    sudo chmod +x /usr/bin/env
    print_success "Created /usr/bin/env"
  fi

  # 2. Dynamic linker stub for precompiled ELFs (/lib64/ld-linux-x86-64.so.2)
  if [ ! -f /lib64/ld-linux-x86-64.so.2 ]; then
    print_info "Creating /lib64/ld-linux-x86-64.so.2 stub..."
    SYSTEM_LD=$(find /run/current-system/sw/lib -maxdepth 1 -name "ld-linux-x86-64.so.*" 2>/dev/null | head -n 1)
    if [ -n "${SYSTEM_LD}" ]; then
      sudo mkdir -p /lib64 2>/dev/null || true
      sudo ln -sf "${SYSTEM_LD}" /lib64/ld-linux-x86-64.so.2
      print_success "Linked /lib64/ld-linux-x86-64.so.2 -> ${SYSTEM_LD}"
    else
      print_warn "Could not locate system ld-linux.so loader"
    fi
  fi

  # 3. Ensure nodejs is available (required by VS Code)
  # 3. Ensure nodejs is available (required by VS Code)
  if ! command -v node >/dev/null 2>&1; then
    case "$(nix profile list 2>/dev/null)" in
    *nodejs*) ;;
    *)
      print_info "Installing nodejs..."
      nix profile add "nixpkgs#nodejs" 2>/dev/null || true
      ;;
    esac
  fi

  # 4. Environment setup for VS Code Server
  NIX_SW_LIBS="/run/current-system/sw/lib:${HOME}/.nix-profile/lib"

  {
    printf '%s\n' '# VS Code Remote Server Environment for NixOS'
    printf '%s\n' "PATH=\"${HOME}/.nix-profile/bin:/run/current-system/sw/bin:\${PATH}\""
    printf '%s\n' "LD_LIBRARY_PATH=\"${NIX_SW_LIBS}:\${LD_LIBRARY_PATH:-}\""
    printf '%s\n' "NIX_LD_LIBRARY_PATH=\"${NIX_SW_LIBS}:\${NIX_LD_LIBRARY_PATH:-}\""
    printf '%s\n' 'NODE_OPTIONS="--max-old-space-size=4096"'
  } >"${HOME}/.vscode-server/env"

  {
    printf '%s\n' '#!/usr/bin/env sh'
    printf '%s\n' "export PATH=\"${HOME}/.nix-profile/bin:/run/current-system/sw/bin:\${PATH}\""
    printf '%s\n' "export LD_LIBRARY_PATH=\"${NIX_SW_LIBS}:\${LD_LIBRARY_PATH:-}\""
    printf '%s\n' "export NIX_LD_LIBRARY_PATH=\"${NIX_SW_LIBS}:\${NIX_LD_LIBRARY_PATH:-}\""
  } >"${HOME}/.vscode-server/server-env-setup"
  chmod +x "${HOME}/.vscode-server/server-env-setup"

  # 5. Pre-download VS Code Server commit if supplied as argument
  case "${1:-}" in
  "") ;;
  *)
    VSCODE_COMMIT="$1"
    case "$(command -v wget 2>/dev/null)" in
    "") nix profile add "nixpkgs#wget" >/dev/null 2>&1 || true ;;
    *) ;;
    esac

    if [ ! -d "${HOME}/.vscode-server/bin/${VSCODE_COMMIT}" ]; then
      print_info "Pre-downloading VS Code Server (${VSCODE_COMMIT})..."
      cd "${HOME}/.vscode-server/bin" || return 1
      if wget -q "https://update.code.visualstudio.com/commit:${VSCODE_COMMIT}/server-linux-x64/stable" -O vscode-server-linux-x64.tar.gz; then
        tar -xzf vscode-server-linux-x64.tar.gz
        mv vscode-server-linux-x64 "${VSCODE_COMMIT}"
        rm -f vscode-server-linux-x64.tar.gz
        print_success "VS Code Server pre-downloaded"
      fi
      cd - >/dev/null || return 1
    fi
    ;;
  esac

  # 6. Ensure SSH service is enabled and running
  if ! systemctl is-active sshd >/dev/null 2>&1; then
    print_info "Starting sshd..."
    sudo systemctl enable sshd 2>/dev/null || true
    sudo systemctl start sshd 2>/dev/null || true
  fi

  print_success "Remote Dev environment ready on $(hostname)!"
}

# ── Remote Helix + tmux workflow ──────────────────────────────────────────────

push_hx() {
  case "$(command -v rsync 2>/dev/null)" in
  "")
    nix profile add "nixpkgs#rsync" >/dev/null 2>&1 || {
      print_error "push_hx: failed to install rsync"
      return 1
    }
    ;;
  *) ;;
  esac

  rsync -av --delete ~/.config/helix/ craole@preci:~/.config/helix/ || {
    print_error "push_hx: rsync failed"
    return 1
  }

  print_success "push_hx: synced Helix config to preci"
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
      print_error "dev: unknown option: $1"
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

# ── Orchestration ─────────────────────────────────────────────────────────────

execute() {
  cleanup

  run() {
    case "${command}" in
    monitors) setup_monitors ;;
    tailscale) setup_tailscale ;;
    utilities) setup_utilities ;;
    rust) setup_rust ;;
    tmux) setup_tmux ;;
    xdg) setup_xdg_open ;;
    portals) setup_portals ;;
    remote-dev) setup_remote_dev ;;
    darkman) setup_darkman ;;
    all)
      setup_xdg_open
      setup_portals
      setup_monitors
      setup_tailscale
      setup_darkman
      setup_utilities
      setup_remote_dev
      setup_rust
      setup_tmux
      ;;
    *) ;;
    esac
  }

  case "${verbosity}" in
  verbose)
    set -x
    run
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

# ── Argument Parsing ──────────────────────────────────────────────────────────

parse_arguments() {
  while [ $# -gt 0 ]; do
    case "$1" in
    monitors | tailscale | utilities | darkman | rust | tmux | xdg | portals | remote-dev | info | all)
      command="$1"
      ;;

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
      print_error "Unknown option: $1"
      show_info
      return 1
      ;;
    esac
    shift
  done
}

# ── Info ─────────────────────────────────────────────────────────────────────

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
    *) compositor="none" ;;
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
      printf '%s\n' "${tailscale_output:-\(no status output\)}" |
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
  "") configuration_details="${configured_monitors:- \(none configured)}" ;;
  "${configured_monitor_signature}") configuration_details="${configured_monitors:- \(none configured)}" ;;
  *) configuration_details="### Detected
${detected_monitors:- \(none detected)}

### Intended
${configured_monitors:- \(none configured)}" ;;
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
  application_details="$(printf '## Required\n%s\n\n## Optional\n%s\n\n## Additional\n%s' "${_required_app_details:- \(none configured)}" "${_optional_app_details:- \(none configured)}" "${_additional_app_details:- \(none configured)}")"
}

show_info() {
  _info="$(
    cat <<EOF
_Usage_        \`. ${name} [COMMAND] [OPTIONS]\`
_Description_  ${description}
_Path_         ${path}
_Author_       ${author}
_Version_      ${version}
_Host_         ${host}
_Compositor_   ${compositor}
_Command_      ${command}
_Verbosity_    ${verbosity}

# APPLICATIONS
${application_details:- \(none configured)}

# COMMANDS
  **info**           Show script, runtime, and configuration information
  **monitors**       Configure monitor layout (Hyprland and niri)
  **tailscale**      Install and connect Tailscale
  **utilities**      Install utility tools
  **rust**           Set up Rust toolchain
  **tmux**           Install tmux
  **portals**        Configure and restart XDG desktop portals (Hyprland)
  **darkman**        Configure Darkman theme hooks and portal settings
  **remote-dev**     Configure VS Code & Zed Remote Dev (Victus & QBX)
  **all**            Run all setup steps (default)

# OPTIONS

## GENERAL
  \`-h, --help   \`            Show this help
  \`-q, --quiet  \`            Suppress all output
  \`-d, --debug  \`            Show detailed internal progress
  \`-v, --verbose\`            Show all commands as they run
  \`    --dry-run\`            Show what would be done without doing it

## MONITOR
  \`--monitor-{tag}-{flag}\`   Set monitor configuration

### Tags
  - **pri**        primary
  - **sec**        secondary
  - **ter**        tertiary

### Flags
  - **name**       an empty name disables the monitor
  - **width**      horizontal resolution
  - **height**     vertical resolution
  - **rate**       refresh rate
  - **pos**        placement can be left, right, top, bottom, or mirror
  - **disable**    force this monitor off (e.g. --monitor-sec-disable)

### Configuration
${configuration_details}

## TAILSCALE (${tailscale_status})
${tailscale_details}

# NOTES
- Defaults are host-specific, resolved via \`hostname\`
- DE/WM is auto-detected via session environment
- When sourced exported variables persist in the parent shell: \`. ${name}\`
- When called as a subshell variables are lost: \`${name}\`
EOF
  )"

  print_markdown "${_info}"
}

# ── Entry Point ───────────────────────────────────────────────────────────────

main() {
  configure || return 1
  parse_arguments "$@" || return 1
  collect_info || return 1
  case "${help_requested}:${command}" in
  1:* | *:info) show_info ;;
  *) execute ;;
  esac
} && main "$@"
