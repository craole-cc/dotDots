#!/bin/sh
# shellcheck enable=all

# TODO: We need an option for info:
# ── Configuration ─────────────────────────────────────────────────────────────

configure() {
	# ── Metadata ────────────────────────────────────────────────────────────
	name="profile"
	home="${DOTS:-${HOME}}"
	path="${home}/${name}"
	description="Temporary bootstrap for NixOS environment"
	author="craole"
	version="0.1.2"

	# ── Runtime ─────────────────────────────────────────────────────────────
	verbosity="info" #? Levels: quiet | info | verbose | debug | dry
	command="all"    #? The active command to run
	help_requested=0

	# ── Display ─────────────────────────────────────────────────────
	#? Detect gum once; shared by all print functions and print_format
	case "$(command -v gum 2>/dev/null)" in
	"")
		_has_gum=0
		# markdown_boundary=""
		;;
	*)
		_has_gum=1
		# markdown_boundary="&#8203;"
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
		# sudo sh -c 'echo on > /sys/kernel/debug/dri/2/eDP-1/force'; sudo sh -c 'echo 1 > /sys/kernel/debug/dri/2/eDP-1/trigger_hotplug'; sleep 2; cat /sys/class/drm/card2-eDP-1/status; hyprctl reload

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
		antigravity-cli
		antigravity-fhs
		cfspeedtest
		fd
		gawk
		gh
		gnused
		gitui
		gum
		hyprland
		nix
		ollama
		rustup
		shellcheck
		shfmt
		shortwave
		speedtest-go
		speedtest-rs
		sudo
		tailscale
		wl-clipboard
	"
	dependencies_required="gawk gnused nix sudo"
	dependencies_optional="fd gum hyprland rustup shellcheck shfmt tailscale wl-clipboard"
}

# ── Helpers ───────────────────────────────────────────────────────────────────
# ------------------------------------------------------------------------------
# get_package_bin PACKAGE
# ------------------------------------------------------------------------------
# Maps a package name to the binary name exposed on PATH.
# ------------------------------------------------------------------------------
get_package_bin() {
	case "$1" in
	antigravity-cli) printf '%s\n' "agy" ;;
	antigravity-fhs) printf '%s\n' "antigravity" ;;
	gawk) printf '%s\n' "awk" ;;
	gnused) printf '%s\n' "sed" ;;
	hyprland) printf '%s\n' "hyprctl" ;;
	wl-clipboard) printf '%s\n' "wl-copy" ;;
	*) printf '%s\n' "$1" ;;
	esac
}

# ------------------------------------------------------------------------------
# get_additional_packages
# ------------------------------------------------------------------------------
# Lists packages that are not declared as required or optional dependencies.
# ------------------------------------------------------------------------------
get_additional_packages() {
	for pkg in ${packages}; do
		case " ${dependencies_required} ${dependencies_optional} " in
		*" ${pkg} "*) ;;
		*) printf '%s\n' "${pkg}" ;;
		esac
	done
}

# ------------------------------------------------------------------------------
# cleanup
# ------------------------------------------------------------------------------
# Removes nix-profile-installed packages that are now provided by the system
# (either /run/current-system/sw/bin or per-user profiles). Safe to call on
# every run; packages not present in the nix profile are silently skipped.
# The candidate list is derived from $packages and the dependency groups.
# ------------------------------------------------------------------------------
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
	case "${compositor}" in
	none)
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
	# is_connected NAME
	# --------------------------------------------------------------------------
	# True if NAME is a currently-present output for the active compositor.
	# --------------------------------------------------------------------------
	is_connected() {
		case "${1:-}" in "") return 1 ;; *) ;; esac
		case "${compositor}" in
		hyprland) hyprctl monitors all 2>/dev/null | grep -q "^Monitor $1" ;;
		niri) niri msg outputs 2>/dev/null | grep -q "Output.*$1" ;;
		*) return 1 ;;
		esac
	}

	# --------------------------------------------------------------------------
	# force_disable NAME
	# --------------------------------------------------------------------------
	# Issues the compositor-specific disable command for NAME.
	# --------------------------------------------------------------------------
	force_disable() {
		case "${1:-}" in "") return 0 ;; *) ;; esac
		case "${compositor}" in
		hyprland) hyprctl keyword monitor "$1, disable" >/dev/null 2>&1 ;;
		niri) niri msg output "$1" off >/dev/null 2>&1 ;;
		*) ;;
		esac
	}

	# --------------------------------------------------------------------------
	# kernel_force_connector NAME
	# --------------------------------------------------------------------------
	# Forces a DRM connector to report "connected" at the kernel level via
	# debugfs, for panels that fail hardware detection but are otherwise usable
	# (e.g. a flaky/overheating eDP panel that needs a hotplug nudge). Locates
	# the connector's debugfs directory by searching for NAME under each
	# /sys/kernel/debug/dri/* entry — debugfs indices do not match
	# /sys/class/drm/cardN numbering, so this cannot be hardcoded. No-op
	# (returns 0) if already connected. Requires sudo; if a password prompt
	# would be needed and none is cached, warns and returns 1 rather than
	# blocking the rest of setup_monitors.
	# --------------------------------------------------------------------------
	kernel_force_connector() {
		_kfc_name="${1:-}"
		case "${_kfc_name}" in "") return 1 ;; *) ;; esac

		#> Locate /sys/class/drm/cardN-NAME/status
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

		#> Already connected — nothing to do
		case "$(cat "${_kfc_status}" 2>/dev/null)" in
		connected) return 0 ;;
		*) ;;
		esac

		#> Don't block on an interactive sudo prompt
		if ! sudo -n true 2>/dev/null; then
			print_warn "kernel_force_connector: sudo needs a password; skipping kernel-level force for ${_kfc_name}"
			return 1
		fi

		#> Locate the matching debugfs directory (indexed by minor, not card number)
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

	# --------------------------------------------------------------------------
	# apply_disables
	# --------------------------------------------------------------------------
	# Forces off any monitor whose *_disable flag is 1, but only when another
	# configured monitor is confirmed connected as a fallback — otherwise warns
	# and leaves it alone rather than risking a blank screen. On success, blanks
	# that tag's _name so the existing blank-name guards in calc_positions,
	# hyprland_apply, and niri_apply skip it entirely for the rest of the run.
	# --------------------------------------------------------------------------
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

	# ── Dispatch ──────────────────────────────────────────────────────────────
	apply_monitor_states
	calc_positions || return 1

	case "${compositor}" in
	hyprland) hyprland_apply ;;
	niri) niri_apply ;;
	*) print_error "Unknown compositor: ${compositor}" ;;
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
	# The package is installed in the user profile; the daemon still runs as root.
	# ----------------------------------------------------------------------------
	install() {
		case "$(command -v tailscale 2>/dev/null)" in
		"")
			print_info "Installing Tailscale from nixpkgs..."
			nix profile add nixpkgs#tailscale || return 1
			;;
		*) ;;
		esac
	}

	# ----------------------------------------------------------------------------
	# daemon_ready
	# ----------------------------------------------------------------------------
	# Returns success when the local tailscaled socket is usable.
	# ----------------------------------------------------------------------------
	daemon_ready() {
		tailscale status >/dev/null 2>&1
	}

	# ----------------------------------------------------------------------------
	# start_systemd
	# ----------------------------------------------------------------------------
	# The Nix profile supplies a service unit, but outside the NixOS module it
	# expects PORT and FLAGS from the generated system configuration. Supplying
	# those values through the systemd manager makes the profile-only unit usable.
	# Runtime enablement intentionally does not attempt to modify immutable /etc.
	# ----------------------------------------------------------------------------
	start_systemd() {
		if ! command -v systemctl >/dev/null 2>&1; then
			return 1
		fi

		sudo systemctl set-environment PORT=0 FLAGS= >/dev/null 2>&1 || return 1
		sudo systemctl reset-failed tailscaled.service >/dev/null 2>&1 || true

		if ! sudo systemctl start tailscaled.service >/dev/null 2>&1; then
			return 1
		fi

		# This lasts for the current boot without writing to NixOS-managed /etc.
		sudo systemctl enable --runtime tailscaled.service >/dev/null 2>&1 || true
		sleep 1
		daemon_ready
	}

	# ----------------------------------------------------------------------------
	# start_manual
	# ----------------------------------------------------------------------------
	# Fallback for systems where the profile-provided service cannot run. The
	# explicit --port=0 is required; an omitted PORT can become an invalid empty
	# systemd flag in the packaged unit.
	# ----------------------------------------------------------------------------
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

	# ----------------------------------------------------------------------------
	# connect
	# ----------------------------------------------------------------------------
	# Brings Tailscale up if it is not already connected. The healthy
	# already-connected path is quiet unless verbose output was requested.
	# ----------------------------------------------------------------------------
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

# ------------------------------------------------------------------------------
# setup_utilities
# ------------------------------------------------------------------------------
# Installs non-dependency packages via `nix profile add` when the
# corresponding binary is not already on PATH. The wl-clipboard package exposes
# the `wl-copy` binary, so the binary name is used for the PATH check while the
# package name is used for installation.
# ------------------------------------------------------------------------------
setup_utilities() {
	# shellcheck disable=SC2086
	for pkg in $(get_additional_packages); do
		bin="$(get_package_bin "${pkg}")"
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
		monitors | tailscale | utilities | rust | tmux | xdg | info | all)
			command="$1"
			;;

		#? Primary monitor flags
		--monitor-pri-disable) monitor_pri_disable=1 ;;
		--monitor-pri-enable) monitor_pri_disable=0 ;;
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

		#? Tertiary monitor flags
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

		#? Verbosity flags
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
		shift #? consume the flag
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
	# ── Detect active compositor ──────────────────────────────────────────────
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

	# Build primary monitor config: enabled if name is set AND disable flag is not 1
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
		"") ;; #? nothing configured at this tier — nothing to show
		*) configured_monitors="- Disabled: ${monitor_pri_name} ${monitor_pri_width}x${monitor_pri_height}@${monitor_pri_rate}" ;;
		esac
		;;
	*)
		configured_monitors="- Primary: ${monitor_pri_name} ${monitor_pri_width}x${monitor_pri_height}@${monitor_pri_rate}"
		configured_monitor_signature="${monitor_pri_name} ${monitor_pri_width}x${monitor_pri_height}@${monitor_pri_rate} ${monitor_pri_pos_xy}"
		;;
	esac

	# Build secondary monitor config: enabled if name is set AND disable flag is not 1
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

	# Build tertiary monitor config: enabled if name is set AND disable flag is not 1
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

# ------------------------------------------------------------------------------
# show_app_status
# ------------------------------------------------------------------------------
# Collects the availability of every configured dependency.
# ------------------------------------------------------------------------------
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

# ------------------------------------------------------------------------------
# show_info
# ------------------------------------------------------------------------------
# Prints command-line help to stdout.
# ------------------------------------------------------------------------------
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
  **info**         Show script, runtime, and configuration information
  **monitors**     Configure monitor layout (Hyprland and niri)
  **tailscale**    Install and connect Tailscale
  **utilities**    Install utility tools
  **rust**         Set up Rust toolchain
  **tmux**         Install tmux
  **all**          Run all setup steps (default)

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

# ------------------------------------------------------------------------------
# main "$@"
# ------------------------------------------------------------------------------
# Top-level entry point. Runs configure → parse_arguments → execute in order,
# forwarding all script arguments to parse_arguments.
# ------------------------------------------------------------------------------
main() {
	configure || return 1
	parse_arguments "$@" || return 1
	collect_info || return 1
	case "${help_requested}:${command}" in
	1:* | *:info) show_info ;;
	*) execute ;;
	esac
} && main "$@"
