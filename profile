#!/bin/sh
# shellcheck enable=all

# TODO: We need an option for info:
# ── Configuration ─────────────────────────────────────────────────────────────

configure() {
  # ── Metadata ────────────────────────────────────────────────────────────
  name="profile"
  home="${DOTS:-${HOME}}"
  path="${home}/${name}"
  host="$(hostname)"
  description="Temporary bootstrap for NixOS environment"
  author="craole"
  version="0.1.2"
  dependencies_required="nix, sudo, awk, sed"
  dependencies_optional="hyprctl, tailscale, fd, gum, wl-copy, shellcheck, shfmt, rustup"

  # ── Runtime ─────────────────────────────────────────────────────────────
  #? Levels: quiet | info | verbose | debug | dry
  verbosity="quiet"
  #? The active command to run
  command="all"

  # ── Display ─────────────────────────────────────────────────────
  #? Detect gum once; shared by all print functions and print_format
  case "$(command -v gum 2>/dev/null)" in
  "") _has_gum=0 ;;
  *) _has_gum=1 ;;
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
    1) printf "%s\n" "$*" | gum format ;;
    *) printf "%s\n" "$*" ;;
    esac
  }

  # ── Host ───────────────────────────────────────────────────────
  case "$(hostname)" in
  Victus)
    monitor_pri_name="eDP-1"
    monitor_pri_width="1920"
    monitor_pri_height="1080"
    monitor_pri_rate="144"

    monitor_sec_name="HDMI-A-1"
    monitor_sec_width="1920"
    monitor_sec_height="1080"
    monitor_sec_rate="60"
    monitor_sec_pos="mirror"

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
    monitor_pri_rate="100"

    monitor_sec_name="DP-3"
    monitor_sec_width="1600"
    monitor_sec_height="900"
    monitor_sec_rate="60"
    monitor_sec_pos="top"

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

  # ── Adhoc Packages ──────────────────────────────────────────────────────
  #? Packages installed on demand via `nix profile add` when absent from PATH.
  #? Add or remove entries here to control what setup_utilities provisions.
  #~@ Adhoc utility packages (package_name — binary checked before install)
  adhoc_packages="
		antigravity-fhs
		cfspeedtest
		fd
		gh
		gitui
		gum
		shellcheck
		shortwave
		speedtest-go
		speedtest-rs
		shfmt
		wl-clipboard
		ollama
		rustup
		tailscale
	"
}

# ── Helpers ───────────────────────────────────────────────────────────────────

# ------------------------------------------------------------------------------
# cleanup
# ------------------------------------------------------------------------------
# Removes nix-profile-installed packages that are now provided by the system
# (either /run/current-system/sw/bin or per-user profiles). Safe to call on
# every run; packages not present in the nix profile are silently skipped.
# The candidate list is driven by $cleanup_packages, defined in configure().
# ------------------------------------------------------------------------------
cleanup() {
  # shellcheck disable=SC2086
  for pkg in ${adhoc_packages}; do
    bin="${pkg}"
    case "${pkg}" in
    wl-clipboard) bin="wl-copy" ;;
    antigravity-fhs) bin="antigravity" ;;
    *) ;;
    esac
    bin_path="$(command -v "${bin}" 2>/dev/null)"
    case "${bin_path:-}" in
    /run/current-system/sw/bin/* | /etc/profiles/per-user/*/bin/*)
      nix profile remove "nixpkgs#${pkg}" 2>/dev/null || true
      print_info "cleanup: removed ${pkg} (now provided by system)"
      ;;
    *) ;;
    esac
  done
}

# ------------------------------------------------------------------------------
# require_arg FLAG VALUE
# ------------------------------------------------------------------------------
# Guards against a missing or flag-looking value after a flag that expects an
# argument. Returns 1 and prints an error when the value is absent or starts
# with "--".
#
# ARGUMENTS
#   FLAG   — the flag name, used only in the error message  (e.g. --monitor-sec-pos)
#   VALUE  — the next token from the argument list          (may be empty)
# ------------------------------------------------------------------------------
require_arg() {
  case "${2:-}" in
  "" | --*)
    print_error "Flag '$1' requires an argument"
    return 1
    ;;
  *) ;;
  esac
}

# ── XDG/OpenURI workaround ────────────────────────────────────────────────────

# ------------------------------------------------------------------------------
# setup_xdg_open
# ------------------------------------------------------------------------------
# Temporary workaround for broken xdg-desktop-portal OpenURI handling.
# Some Electron apps, including Antigravity, call xdg-open for browser sign-in.
# On this system, gio open works but xdg-open fails, so we shadow xdg-open with
# a user-local wrapper that delegates to gio.
# ------------------------------------------------------------------------------
setup_xdg_open() {
  mkdir -p "${HOME}/.local/bin"

  cat >"${HOME}/.local/bin/xdg-open" <<'EOF'
#!/usr/bin/env sh
exec gio open "$@"
EOF

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

# ── Monitors ──────────────────────────────────────────────────────────────────

# ------------------------------------------------------------------------------
# setup_monitors
# ------------------------------------------------------------------------------
# Configures multi-monitor layout in Hyprland by editing hyprland.conf and
# reloading the compositor. Skips the reload when current positions already
# match the desired layout. Tertiary monitor handling is skipped when monitor_ter_name
# is empty.
# ------------------------------------------------------------------------------
setup_monitors() {

  # ── Detect active compositor ──────────────────────────────────────────────
  # HYPRLAND_INSTANCE_SIGNATURE and NIRI_SOCKET are set by their respective
  # compositors for every process inside a live session. More reliable than
  # checking `command -v` since the binaries can be on PATH without a session.
  case "${HYPRLAND_INSTANCE_SIGNATURE:-}" in
  ?*) _compositor="hyprland" ;;
  *)
    case "${NIRI_SOCKET:-}" in
    ?*) _compositor="niri" ;;
    *) _compositor="" ;;
    esac
    ;;
  esac

  case "${_compositor}" in
  "")
    print_info "setup_monitors: no supported compositor detected (Hyprland or niri); skipping"
    return 0
    ;;
  *) ;;
  esac

  # --------------------------------------------------------------------------
  # build_res WIDTH HEIGHT RATE
  # --------------------------------------------------------------------------
  # Outputs: WIDTHxHEIGHT@RATE  (e.g. 2560x1440@100)
  # Used by both compositor backends.
  # --------------------------------------------------------------------------
  build_res() {
    printf '%sx%s@%s' "$1" "$2" "$3"
  }

  # --------------------------------------------------------------------------
  # calc_positions
  # --------------------------------------------------------------------------
  # Derives the XY origin for each monitor from monitor_sec_pos (and
  # monitor_ter_pos when a third connector is configured).
  # Populates: monitor_pri_pos_xy, monitor_sec_pos_xy, monitor_ter_pos_xy
  # Compositor-agnostic — both backends use the same geometry.
  # --------------------------------------------------------------------------
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

  # --------------------------------------------------------------------------
  # hyprland_apply
  # --------------------------------------------------------------------------
  # Issues `hyprctl keyword monitor` commands. Queries current layout first
  # and skips the reload when positions already match.
  # hyprctl failure is non-fatal: empty current position forces a reload,
  # which is the safe worst case.
  # --------------------------------------------------------------------------
  hyprland_apply() {
    _pri_res="$(build_res "${monitor_pri_width}" "${monitor_pri_height}" "${monitor_pri_rate}")"
    _sec_res="$(build_res "${monitor_sec_width}" "${monitor_sec_height}" "${monitor_sec_rate}")"

    case "${monitor_sec_pos}" in
    mirror)
      case "${monitor_ter_name:-}" in
      "") ;;
      *)
        print_error "hyprland: tertiary monitor with monitor_sec_pos=mirror is not supported"
        return 1
        ;;
      esac
      hyprctl keyword monitor "${monitor_pri_name}, ${_pri_res}, ${monitor_pri_pos_xy}, 1"
      hyprctl keyword monitor "${monitor_sec_name}, ${_sec_res}, auto, 1, mirror, ${monitor_pri_name}"
      return 0
      ;;
    *) ;;
    esac

    #? Non-fatal: empty string on failure forces a reload (safe worst case)
    _monitors="$(hyprctl monitors 2>/dev/null)" || _monitors=""
    _pri_current="$(printf '%s\n' "${_monitors}" |
      awk '/Monitor '"${monitor_pri_name}"'/{found=1} found && /at /{print $3; exit}')"
    _sec_current="$(printf '%s\n' "${_monitors}" |
      awk '/Monitor '"${monitor_sec_name}"'/{found=1} found && /at /{print $3; exit}')"

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
      hyprctl keyword monitor "${monitor_pri_name}, ${_pri_res}, ${monitor_pri_pos_xy}, 1"
      hyprctl keyword monitor "${monitor_sec_name}, ${_sec_res}, ${monitor_sec_pos_xy}, 1"
      case "${monitor_ter_name:-}" in
      "") ;;
      *)
        _ter_res="$(build_res "${monitor_ter_width}" "${monitor_ter_height}" "${monitor_ter_rate}")"
        hyprctl keyword monitor "${monitor_ter_name}, ${_ter_res}, ${monitor_ter_pos_xy}, 1"
        ;;
      esac
      ;;
    *) ;;
    esac
  }

  # --------------------------------------------------------------------------
  # niri_get_pos OUTPUT_NAME
  # --------------------------------------------------------------------------
  # Parses `niri msg outputs` JSON (pretty-printed, one key per line) to
  # extract the logical x,y position of the named output.
  # Prints "XxY" on success; empty string when not found or output is off
  # (logical: null). Empty result is non-fatal — callers treat it as unknown
  # and apply the full reload, which is idempotent.
  # --------------------------------------------------------------------------
  niri_get_pos() {
    niri msg outputs 2>/dev/null | awk -v target="$1" '
      BEGIN { in_output=0; in_logical=0; x=""; y="" }

      # Match the output block by name; reset state if another name is seen
      /"name":/ {
        if (index($0, "\"" target "\"")) {
          in_output=1; in_logical=0; x=""; y=""
        } else if (in_output) {
          in_output=0; in_logical=0
        }
      }

      # null logical means the output is off — skip
      in_output && /"logical": *null/ { in_output=0 }

      in_output && /"logical":/ { in_logical=1 }

      in_logical && /"x":/ {
        line=$0
        sub(/.*"x": */, "", line)
        sub(/[^0-9-].*/, "", line)
        x=line
      }
      in_logical && /"y":/ {
        line=$0
        sub(/.*"y": */, "", line)
        sub(/[^0-9-].*/, "", line)
        y=line
        printf "%sx%s", x, y
        exit
      }
    '
  }

  # --------------------------------------------------------------------------
  # niri_apply
  # --------------------------------------------------------------------------
  # Issues `niri msg output <name> mode <res> position x=<x> y=<y>` commands.
  # Uses niri_get_pos to skip unchanged outputs (non-fatal if query fails).
  #
  # Mirror note: niri has no native output mirroring. When monitor_sec_pos is
  # "mirror" we configure the primary only and warn; the secondary is left
  # as-is rather than silently placed at an arbitrary position.
  # --------------------------------------------------------------------------
  niri_apply() {
    _pri_res="$(build_res "${monitor_pri_width}" "${monitor_pri_height}" "${monitor_pri_rate}")"
    _sec_res="$(build_res "${monitor_sec_width}" "${monitor_sec_height}" "${monitor_sec_rate}")"

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

  # ── Dispatch ──────────────────────────────────────────────────────────────
  calc_positions || return 1

  case "${_compositor}" in
  hyprland) hyprland_apply ;;
  niri) niri_apply ;;
  *) print_error "Unknown compositor: ${_compositor}" ;;
  esac
}

#? Renders one monitor status line, or nothing if NAME is unset
#? ARGS: LABEL NAME WIDTH HEIGHT RATE [POS]
get_monitor_status() {
  _label="$1" _name="$2" _width="$3" _height="$4" _rate="$5" _pos="${6:-}"
  case "${_name}" in
  "") return 0 ;;
  *)
    case "${_pos}" in
    "")
      printf -- "- %s: %s %sx%s@%s\n" \
        "${_label}" "${_name}" "${_width:-?}" "${_height:-?}" "${_rate:-?}"
      ;;
    *)
      printf -- "- %s: %s %sx%s@%s %s\n" \
        "${_label}" "${_name}" "${_width:-?}" "${_height:-?}" "${_rate:-?}" "${_pos}"
      ;;
    esac
    ;;
  esac
}

# ── Tailscale ─────────────────────────────────────────────────────────────────

# ------------------------------------------------------------------------------
# setup_tailscale
# ------------------------------------------------------------------------------
# Ensures Tailscale is installed, the daemon is running, and the node is
# authenticated. Installs from nixpkgs only when the binary is absent; starts
# the daemon only when no existing tailscaled process is found.
# ------------------------------------------------------------------------------
setup_tailscale() {

  # ----------------------------------------------------------------------------
  # install
  # ----------------------------------------------------------------------------
  # Adds the tailscale package from nixpkgs if the binary is not already on PATH.
  # ----------------------------------------------------------------------------
  install() {
    case "$(command -v tailscale 2>/dev/null)" in
    "") nix profile add nixpkgs#tailscale ;;
    *) ;;
    esac
  }

  # ----------------------------------------------------------------------------
  # start_daemon
  # ----------------------------------------------------------------------------
  # Launches tailscaled in the background when no running instance is detected.
  # Waits briefly for the socket to become available before continuing.
  # ----------------------------------------------------------------------------
  start_daemon() {
    if tailscale status >/dev/null 2>&1; then
      return
    fi

    if pgrep tailscaled >/dev/null 2>&1; then
      sudo pkill tailscaled
      sleep 1
    fi

    sudo tailscaled --state=/var/lib/tailscale/tailscaled.state 2>&1 |
      sudo tee /tmp/tailscaled.log >/dev/null &

    sleep 2
  }
  # ----------------------------------------------------------------------------
  # connect
  # ----------------------------------------------------------------------------
  # Brings the Tailscale node up if it is not already connected. When already
  # connected and verbosity is non-quiet, prints status for confirmation.
  # ----------------------------------------------------------------------------

  connect() {
    if ! tailscale status >/dev/null 2>&1; then
      sudo tailscale up
      return
    fi
    print_success "Tailscale already connected"
  }

  install
  start_daemon
  connect
}

# ── Utilities ─────────────────────────────────────────────────────────────────

# ------------------------------------------------------------------------------
# setup_utilities
# ------------------------------------------------------------------------------
# Installs packages listed in $adhoc_packages via `nix profile add` when the
# corresponding binary is not already on PATH. The wl-clipboard package exposes
# the `wl-copy` binary, so the binary name is used for the PATH check while the
# package name is used for installation.
# ------------------------------------------------------------------------------
setup_utilities() {
  # shellcheck disable=SC2086
  for pkg in ${adhoc_packages}; do
    bin="${pkg}"
    case "${pkg}" in
    wl-clipboard) bin="wl-copy" ;;
    antigravity-fhs) bin="antigravity" ;;
    *) ;;
    esac
    case "$(command -v "${bin}" 2>/dev/null)" in
    "") NIXPKGS_ALLOW_UNFREE=1 nix profile add --impure "nixpkgs#${pkg}" ;;
    *) ;;
    esac
  done
}

fix_net() {
  sudo tailscale down 2>/dev/null || true
  sudo pkill tailscaled 2>/dev/null || true

  _iface="$(ip route 2>/dev/null | awk '/default/ { print $5; exit }')" || _iface=""
  case "${_iface}" in "") ;; *)
    sudo resolvectl revert "${_iface}" 2>/dev/null || true
    ;;
  esac

  sudo resolvectl flush-caches 2>/dev/null || true

  print_success "Stopped Tailscale and reset DNS for the default interface"
}

# ── Clipboard ─────────────────────────────────────────────────────────────────

# ------------------------------------------------------------------------------
# clip [OPTIONS] [PATH ...]
# ------------------------------------------------------------------------------
# Interactively selects files under one or more paths and copies their contents
# to the Wayland clipboard in fenced-code-block format, ready to paste into a
# chat or document.
#
# Each file is wrapped as:
#   ```
#   # /path/to/file
#   <file contents>
#   ```
#
# ARGUMENTS
#   PATH          File or directory to include. Defaults to the current directory
#                 when omitted. Multiple paths are accepted.
#
# OPTIONS
#   --no-ignore   Pass --no-ignore to fd (include files hidden by .gitignore etc.)
#   --no-recurse  Do not recurse into subdirectories
#
# DEPENDENCIES
#   gum      Interactive prompts
#   fd       File discovery
#   wl-copy  Wayland clipboard writer
# ------------------------------------------------------------------------------
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

  # ----------------------------------------------------------------------------
  # collect_files TARGET
  # ----------------------------------------------------------------------------
  # Resolves TARGET to an absolute path and emits selected file paths to stdout.
  # For files, prompts the user to include or skip. For directories, offers
  # "all" (every file recursively), "recurse" (inspect each entry), or "skip".
  # Returns 1 if the user cancels via Ctrl-C (gum exit code 130).
  # ----------------------------------------------------------------------------
  collect_files() {
    target="$1"

    #> Resolve relative paths — check ${HOME} first, then CWD
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
      #> Prompt for individual file inclusion
      gum confirm "Include ${target}?" </dev/tty >/dev/tty 2>&1
      exit_code=$?
      case "${exit_code}" in
      0) printf "%s\n" "${target}" ;; #? Confirmed — emit path
      130)
        print_warn "clip: cancelled"
        return 1
        ;;
      *) ;; #? Declined — emit nothing
      esac

    elif [ -d "${target}" ]; then
      #> Prompt for directory handling strategy
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
        #> Emit every file under the directory
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
        #> Inspect each immediate entry individually
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

  # ── Collect selected file paths ────────────────────────────────────────
  #> Accumulate all emitted paths into a temp file to avoid subshell scoping
  selected=""
  _collect_tmp="$(mktemp)"
  # shellcheck disable=SC2086
  for clip_path in ${clip_paths}; do
    collect_files "${clip_path}" >>"${_collect_tmp}"
  done

  #> Read collected paths back into $selected from the temp file
  while IFS= read -r file; do
    selected="$(printf "%s\n%s" "${selected}" "${file}")"
  done <"${_collect_tmp}"
  rm -f "${_collect_tmp}"

  #> Strip blank lines introduced by the accumulation pattern
  selected="$(printf "%s" "${selected}" | sed '/^$/d')"

  case "${selected}" in
  "")
    print_error "clip: nothing selected"
    return 1
    ;;
  *) ;;
  esac

  # ── Build clipboard content ────────────────────────────────────────────
  file_count="$(printf "%s\n" "${selected}" | wc -l | tr -d ' ')"
  print_info "clip: Building content from ${file_count} file(s)..."

  #> Write $selected to a temp file so the while-read loop runs in the
  #  current shell (piping would create a subshell, losing $content)
  content=""
  _content_tmp="$(mktemp)"
  printf "%s\n" "${selected}" >"${_content_tmp}"

  while IFS= read -r file; do
    print_verbose "clip: adding ${file}"

    #> Wrap each file in a fenced code block with its path as a header
    # TODO: Command substitution strips trailing newlines, so files ending with \n (which is most of them) will have that stripped in the clipboard output. Not fixable without a temp file or || printf x trick, but worth noting in the function's doc comment.
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

# ------------------------------------------------------------------------------
# setup_rust
# ------------------------------------------------------------------------------
# Bootstraps the Rust toolchain via rustup. Installs rustup from nixpkgs when
# absent, then ensures the stable toolchain is active with clippy, rustfmt, and
# rust-analyzer components.
# ------------------------------------------------------------------------------
setup_rust() {

  # ----------------------------------------------------------------------------
  # install
  # ----------------------------------------------------------------------------
  # Adds rustup from nixpkgs if the binary is not already on PATH.
  # ----------------------------------------------------------------------------
  install() {
    case "$(command -v rustup 2>/dev/null)" in
    "")
      print_info "Installing rustup..."
      nix profile add "nixpkgs#rustup"
      ;;
    *) ;;
    esac
  }

  # ----------------------------------------------------------------------------
  # apply
  # ----------------------------------------------------------------------------
  # Switches to the stable toolchain and installs development components when
  # they are not already present. Skips silently when stable is already active.
  # ----------------------------------------------------------------------------
  apply() {
    case "$(rustup toolchain list 2>/dev/null)" in
    *"stable"*) ;;
    *)
      print_info "Setting up stable toolchain..."
      rustup default stable
      #~@ Essential development components
      rustup component add clippy rustfmt rust-analyzer
      ;;
    esac
  }

  install
  apply
}

# ── Tmux ──────────────────────────────────────────────────────────────────────

# ------------------------------------------------------------------------------
# setup_tmux
# ------------------------------------------------------------------------------
# Ensures tmux is installed via nix profile if the binary is not on PATH.
# ------------------------------------------------------------------------------
setup_tmux() {
  case "$(command -v tmux 2>/dev/null)" in
  "")
    print_info "Installing tmux..."
    nix profile add "nixpkgs#tmux"
    ;;
  *) ;;
  esac
}

# ── Remote Helix + tmux workflow ──────────────────────────────────────────────

# ------------------------------------------------------------------------------
# push_hx
# ------------------------------------------------------------------------------
# Syncs local ~/.config/helix to craole@preci:~/.config/helix (one-way).
# ------------------------------------------------------------------------------
push_hx() {
  case "$(command -v rsync 2>/dev/null)" in
  "")
    # Ensure rsync is available
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

  print_success "push_hx: synced Helix config to prec"
  # Ensure tmux is available (on local machine)
  case "$(command -v tmux 2>/dev/null)" in
  "") nix profile add "nixpkgs#tmux" >/dev/null 2>&1 ;;
  *) ;;
  esac
}

# ------------------------------------------------------------------------------
# dev
# ------------------------------------------------------------------------------
# One-command remote dev entrypoint:
#   1. Sync local Helix config to prec (push_hx)
#   2. SSH into prec and attach/create tmux session "dots"
#
# ARGUMENTS
#   -n, --no-sync   Skip Helix sync; SSH + tmux only
# ------------------------------------------------------------------------------
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

  # Inline tmux attach/create logic (works on remote without extra setup)
  ssh craole@preci -t "tmux attach-session -t dots 2>/dev/null || tmux new-session -s dots"
}

# ── Orchestration ─────────────────────────────────────────────────────────────

# ------------------------------------------------------------------------------
# execute
# ------------------------------------------------------------------------------
# Dispatches to the appropriate setup function(s) based on $command, honouring
# the $verbosity level. In dry-run mode, prints what would be executed without
# running anything.
# ------------------------------------------------------------------------------
execute() {
  cleanup

  # ----------------------------------------------------------------------------
  # run
  # ----------------------------------------------------------------------------
  # Inner dispatcher — isolated so verbosity wrappers (set -x, /dev/null) can
  # wrap the entire invocation cleanly.
  # ----------------------------------------------------------------------------
  run() {
    case "${command}" in
    monitors) setup_monitors ;;
    tailscale) setup_tailscale ;;
    utilities) setup_utilities ;;
    rust) setup_rust ;;
    tmux) setup_tmux ;;
    xdg) setup_xdg_open ;;
    all)
      #~@ Full setup sequence
      setup_xdg_open
      setup_monitors
      setup_tailscale
      setup_utilities
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

# ------------------------------------------------------------------------------
# parse_arguments "$@"
# ------------------------------------------------------------------------------
# Parses positional and flag arguments, populating the variables set by
# configure(). Unknown flags are treated as errors.
#
# NOTE: Temporary shim — replace with proper CLI once the bootstrap project
#       is built.
# ------------------------------------------------------------------------------
parse_arguments() {
  while [ $# -gt 0 ]; do
    case "$1" in
    monitors | tailscale | utilities | rust | tmux | xdg | all) #> Named command — set as the operation to run
      command="$1"
      ;;

    #? Primary monitor flags
    --monitor-pri-name)
      require_arg "$1" "$2" || return 1
      monitor_pri_name="$2"
      shift #? consume the value
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

    #? Secondary monitor flags
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

    #? Tertiary monitor flags
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

    #? Verbosity flags
    -q | --quiet) verbosity="quiet" ;;
    -d | --debug) verbosity="debug" ;;
    -v | --verbose) verbosity="verbose" ;;
    --dry-run) verbosity="dry" ;;

    -h | --help)
      usage
      return 0
      ;;
    *)
      print_error "Unknown option: $1"
      usage
      return 1
      ;;
    esac
    shift #? consume the flag
  done
}

# ── Usage ─────────────────────────────────────────────────────────────────────

# ------------------------------------------------------------------------------
# usage
# ------------------------------------------------------------------------------
# Prints command-line help to stdout.
# ------------------------------------------------------------------------------
usage() {
  #? Build the current-monitors block once, with unset monitors omitted entirely
  _active_monitors="$(
    {
      get_monitor_status "Primary" "${monitor_pri_name:-}" "${monitor_pri_width:-}" "${monitor_pri_height:-}" "${monitor_pri_rate:-}"
      get_monitor_status "Secondary" "${monitor_sec_name:-}" "${monitor_sec_width:-}" "${monitor_sec_height:-}" "${monitor_sec_rate:-}" "${monitor_sec_pos:-}"
      get_monitor_status "Tertiary" "${monitor_ter_name:-}" "${monitor_ter_width:-}" "${monitor_ter_height:-}" "${monitor_ter_rate:-}" "${monitor_ter_pos:-}"
    } | sed '/^$/d'
  )"

  _help="$(
    cat <<EOF
**Description:** _${description}_
**Path:** _${path}_
**Author:** _${author}_
**Version:** _${version}_
**Usage:** \`. ${name} [COMMAND] [OPTIONS]\`

# COMMANDS
  **monitors**      Configure monitor layout (Hyprland and niri)
  **tailscale**     Install and connect Tailscale
  **utilities**     Install utility tools
  **rust**          Set up Rust toolchain
  **tmux**          Install tmux
  **all**           Run all setup steps (default)

# MONITOR:
  \`--monitor-{tag}-{flag}\` Set monitor configuration

## Tags
  - pri: primary
  - sec: secondary
  - ter: tertiary

## Flags
  - name: an empty name disables the monitor
  - width: horizontal resolution
  - height: vertical resolution
  - rate: refresh rate
  - pos: placement can be left, right, top, bottom, or mirror

## Current
${_active_monitors:- \(none configured)}

# VERBOSITY
  \`-q, --quiet\`            Suppress all output
  \`-d, --debug\`            Show detailed internal progress
  \`-v, --verbose\`          Show all commands as they run
      \`--dry-run\`          Show what would be done without doing it

# OTHER
  \`-h, --help\`             Show this help

# DEPENDENCIES
  ## Required: _${dependencies_required}_
  ## Optional: _${dependencies_optional}_

# NOTES
- Defaults are host-specific, resolved via \`hostname\` (current: _${host}_).
- DE/WM is auto-detected via session environment
- When sourced exported variables persist in the parent shell: \`. ${name}\`
- When called as a subshell variables are lost: \`${name}\`
EOF
  )"

  print_markdown "${_help}"
}

# ── Entry Point ───────────────────────────────────────────────────────────────

# ------------------------------------------------------------------------------
# main "$@"
# ------------------------------------------------------------------------------
# Top-level entry point. Runs configure → parse_arguments → execute in order,
# forwarding all script arguments to parse_arguments.
# ------------------------------------------------------------------------------
main() {
  configure || return 1
  parse_arguments "$@" || return 1
  execute
} && main "$@"
