#!/bin/sh
# shellcheck enable=all
# ==============================================================================
# profile — NixOS Bootstrap Script
# ==============================================================================
#
# SYNOPSIS
#   . ~/profile [COMMAND] [OPTIONS]
#
# DESCRIPTION
#   Temporary bootstrap script for configuring a NixOS environment until the
#   proper bootstrap project is built. Handles monitor layout, Tailscale VPN,
#   utility installation, and Rust toolchain setup.
#
# COMMANDS
#   monitors      Configure Hyprland monitor layout only
#   tailscale     Install and connect Tailscale only
#   utilities     Install utility tools only
#   rust          Set up the Rust toolchain only
#   tmux          Install tmux only
#   all           Run all setup steps (default)
#
# OPTIONS
#   Monitor — primary:
#     --pri-name   NAME   Connector identifier         (default: HDMI-A-3)
#     --pri-width  PX     Horizontal resolution        (default: 2560)
#     --pri-height PX     Vertical resolution          (default: 1440)
#     --pri-rate   HZ     Refresh rate                 (default: 100)
#
#   Monitor — secondary:
#     --sec-name   NAME   Connector identifier         (default: DP-3)
#     --sec-width  PX     Horizontal resolution        (default: 1600)
#     --sec-height PX     Vertical resolution          (default: 900)
#     --sec-rate   HZ     Refresh rate                 (default: 60)
#     --sec-pos    POS    Placement: left|right|top|bottom  (default: top)
#
#   Monitor — tertiary:
#     --ter-name   NAME   Connector identifier         (default: "")
#     --ter-width  PX     Horizontal resolution        (default: 1920)
#     --ter-height PX     Vertical resolution          (default: 1080)
#     --ter-rate   HZ     Refresh rate                 (default: 60)
#     --ter-pos    POS    Placement: left|right|top|bottom  (default: right)
#
#   Verbosity:
#     -q, --quiet     Suppress all output (default)
#     -d, --debug     Show detailed internal progress
#     -v, --verbose   Trace all commands as they execute
#         --dry-run   Preview actions without executing them
#
#   Other:
#     -h, --help      Print this help and exit
#
# DEPENDENCIES
#   Required:  nix, sudo, awk, sed
#   Optional:  hyprctl, tailscale, fd, gum, wl-copy, shellcheck, shfmt, rustup
#
# AUTHOR
#   craole
#
# VERSION
#   0.1.0
#
# NOTES
#   Sourced as `. ~/profile` so it can export environment changes to the
#   calling shell. Running it as a child process (sh ~/profile) still works
#   but any exported variables will be lost when the subshell exits.
# ==============================================================================

# ── Configuration ─────────────────────────────────────────────────────────────

configure() {
	# ── Metadata ────────────────────────────────────────────────────────────
	#~@ Script identity
	name="profile"
	description="Temporary bootstrap for NixOS environment"
	author="craole"
	version="0.1.0"
	dependencies="nix, sudo, awk, sed, hyprctl, tailscale, fd, gum, wl-copy, shellcheck, shfmt"

	# ── Verbosity ───────────────────────────────────────────────────────────
	#? Levels: quiet | info | verbose | debug | dry
	verbosity="quiet"

	# ── Print Functions ─────────────────────────────────────────────────────
	#? Use gum for styled output when available; fall back to plain printf
	case "$(command -v gum 2>/dev/null)" in
	"")
		#> Plain printf fallbacks — no external dependency
		print_debug() { printf "debug: %s\n" "$*"; }
		print_info() { printf "info:  %s\n" "$*"; }
		print_warn() { printf "warn:  %s\n" "$*"; }
		print_error() { printf "error: %s\n" "$*" >&2; }
		print_success() { printf "ok:    %s\n" "$*"; }
		;;
	*)
		#> Styled gum output with log levels
		print_debug() { gum log --level debug --message.foreground="99" "$*"; }
		print_info() { gum log --level info "$*"; }
		print_warn() { gum log --level warn "$*"; }
		print_error() { gum log --level error "$*"; }
		print_success() { gum log --level info "$*"; }
		;;
	esac

	# ── Defaults ────────────────────────────────────────────────────────────

	#? The active command to run
	command="all"

	# ── Adhoc Packages ──────────────────────────────────────────────────────
	#? Packages installed on demand via `nix profile add` when absent from PATH.
	#? Add or remove entries here to control what setup_utilities provisions.
	#~@ Adhoc utility packages (package_name — binary checked before install)
	adhoc_packages="
		antigravity-cli
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
			"

	#? Packages to prune from nix profile once the system provides them.
	#? Mirror adhoc_packages plus any toolchain packages managed here.
	#~@ Packages eligible for cleanup when found on the system PATH
	cleanup_packages="
		antigravity-cli
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

	# ── Primary Monitor ─────────────────────────────────────────────────────
	#? The main display — typically the highest-resolution panel
	#~@ Primary monitor defaults
	pri_name="HDMI-A-2"
	pri_width="2560"
	pri_height="1440"
	pri_rate="100"

	# ── Secondary Monitor ───────────────────────────────────────────────────
	#? The secondary display and its position relative to the primary
	#~@ Secondary monitor defaults
	sec_name="DP-3"
	sec_width="1600"
	sec_height="900"
	sec_rate="60"
	sec_pos="top"

	# ── Tertiary Monitor ────────────────────────────────────────────────────
	#? Leave ter_name empty to disable tertiary monitor handling entirely
	#~@ Tertiary monitor defaults
	ter_name=""
	ter_width="1920"
	ter_height="1080"
	ter_rate="60"
	ter_pos="right"
}

# ── Helpers ───────────────────────────────────────────────────────────────────

# ------------------------------------------------------------------------------
# require_arg FLAG VALUE
# ------------------------------------------------------------------------------
# Guards against a missing or flag-looking value after a flag that expects an
# argument. Returns 1 and prints an error when the value is absent or starts
# with "--".
#
# ARGUMENTS
#   FLAG   — the flag name, used only in the error message  (e.g. --sec-pos)
#   VALUE  — the next token from the argument list          (may be empty)
# ------------------------------------------------------------------------------
require_arg() {
	case "${2:-}" in
	"" | --*)
		print_error "Flag '$1' requires an argument"
		return 1
		;;
	esac
}

# ── Usage ─────────────────────────────────────────────────────────────────────

# ------------------------------------------------------------------------------
# usage
# ------------------------------------------------------------------------------
# Prints command-line help to stdout.
# ------------------------------------------------------------------------------
usage() {
	printf 'Usage: . ~/profile [COMMAND] [OPTIONS]\n\n'

	printf 'Commands:\n'
	printf '  monitors      Configure Hyprland monitor layout only\n'
	printf '  tailscale     Install and connect Tailscale only\n'
	printf '  utilities     Install utility tools only\n'
	printf '  rust          Set up Rust toolchain only\n'
	printf '  tmux        Install tmux only\n'
	printf '  all           Run all setup steps (default)\n\n'

	printf 'Monitor options — primary:\n'
	printf '  --pri-name   NAME   Connector identifier       (default: HDMI-A-3)\n'
	printf '  --pri-width  PX     Horizontal resolution      (default: 2560)\n'
	printf '  --pri-height PX     Vertical resolution        (default: 1440)\n'
	printf '  --pri-rate   HZ     Refresh rate               (default: 100)\n\n'

	printf 'Monitor options — secondary:\n'
	printf '  --sec-name   NAME   Connector identifier       (default: DP-3)\n'
	printf '  --sec-width  PX     Horizontal resolution      (default: 1600)\n'
	printf '  --sec-height PX     Vertical resolution        (default: 900)\n'
	printf '  --sec-rate   HZ     Refresh rate               (default: 60)\n'
	printf '  --sec-pos    POS    Placement: left|right|top|bottom  (default: top)\n\n'

	printf 'Monitor options — tertiary (omit --ter-name to disable):\n'
	printf '  --ter-name   NAME   Connector identifier       (default: disabled)\n'
	printf '  --ter-width  PX     Horizontal resolution      (default: 1920)\n'
	printf '  --ter-height PX     Vertical resolution        (default: 1080)\n'
	printf '  --ter-rate   HZ     Refresh rate               (default: 60)\n'
	printf '  --ter-pos    POS    Placement: left|right|top|bottom  (default: right)\n\n'

	printf 'Verbosity:\n'
	printf '  -q, --quiet     Suppress all output\n'
	printf '  -d, --debug     Show detailed internal progress\n'
	printf '  -v, --verbose   Show all commands as they run\n'
	printf '      --dry-run   Show what would be done without doing it\n\n'

	printf 'Other:\n'
	printf '  -h, --help    Show this help\n'
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
		monitors | tailscale | utilities | rust |  tmux | all)
			#> Named command — set as the operation to run
			command="$1"
			;;

		#? Primary monitor flags
		--pri-name)
			require_arg "$1" "$2" || return 1
			pri_name="$2"
			shift #? consume the value
			;;
		--pri-width)
			require_arg "$1" "$2" || return 1
			pri_width="$2"
			shift
			;;
		--pri-height)
			require_arg "$1" "$2" || return 1
			pri_height="$2"
			shift
			;;
		--pri-rate)
			require_arg "$1" "$2" || return 1
			pri_rate="$2"
			shift
			;;

		#? Secondary monitor flags
		--sec-name)
			require_arg "$1" "$2" || return 1
			sec_name="$2"
			shift
			;;
		--sec-width)
			require_arg "$1" "$2" || return 1
			sec_width="$2"
			shift
			;;
		--sec-height)
			require_arg "$1" "$2" || return 1
			sec_height="$2"
			shift
			;;
		--sec-rate)
			require_arg "$1" "$2" || return 1
			sec_rate="$2"
			shift
			;;
		--sec-pos)
			require_arg "$1" "$2" || return 1
			sec_pos="$2"
			shift
			;;

		#? Tertiary monitor flags
		--ter-name)
			require_arg "$1" "$2" || return 1
			ter_name="$2"
			shift
			;;
		--ter-width)
			require_arg "$1" "$2" || return 1
			ter_width="$2"
			shift
			;;
		--ter-height)
			require_arg "$1" "$2" || return 1
			ter_height="$2"
			shift
			;;
		--ter-rate)
			require_arg "$1" "$2" || return 1
			ter_rate="$2"
			shift
			;;
		--ter-pos)
			require_arg "$1" "$2" || return 1
			ter_pos="$2"
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

# ── Cleanup ───────────────────────────────────────────────────────────────────

# ------------------------------------------------------------------------------
# cleanup
# ------------------------------------------------------------------------------
# Removes nix-profile-installed packages that are now provided by the system
# (either /run/current-system/sw/bin or per-user profiles). Safe to call on
# every run; packages not present in the nix profile are silently skipped.
# The candidate list is driven by $cleanup_packages, defined in configure().
# ------------------------------------------------------------------------------
cleanup() {
	for pkg in $cleanup_packages; do
		bin="$(command -v "$pkg" 2>/dev/null)"
		case "${bin:-}" in
		/run/current-system/sw/bin/* | /etc/profiles/per-user/*/bin/*)
			#> Remove the nix-profile copy; ignore errors if already absent
			nix profile remove "nixpkgs#$pkg" 2>/dev/null || true
			case "$verbosity" in
			quiet) ;;
			*) print_info "cleanup: removed ${pkg} from nix profile (now provided by system)" ;;
			esac
			;;
		esac
	done
}

# ── Monitors ──────────────────────────────────────────────────────────────────

# ------------------------------------------------------------------------------
# setup_monitors
# ------------------------------------------------------------------------------
# Configures multi-monitor layout in Hyprland by editing hyprland.conf and
# reloading the compositor. Skips the reload when current positions already
# match the desired layout. Tertiary monitor handling is skipped when ter_name
# is empty.
#
# Reads globals: pri_name, pri_width, pri_height, pri_rate
#                sec_name, sec_width, sec_height, sec_rate, sec_pos
#                ter_name, ter_width, ter_height, ter_rate, ter_pos
# ------------------------------------------------------------------------------
setup_monitors() {

	# ----------------------------------------------------------------------------
	# build_res NAME WIDTH HEIGHT RATE
	# ----------------------------------------------------------------------------
	# Assembles the Hyprland resolution string from discrete components.
	# Outputs: WIDTHxHEIGHT@RATE  (e.g. 2560x1440@100)
	# ----------------------------------------------------------------------------
	build_res() {
		printf '%sx%s@%s' "$2" "$3" "$4"
	}

	# ----------------------------------------------------------------------------
	# calc_positions
	# ----------------------------------------------------------------------------
	# Derives the XY origin for each monitor based on the desired sec_pos (and
	# ter_pos for a third panel). Populates pri_pos_xy, sec_pos_xy, and
	# ter_pos_xy. Returns 1 for an unrecognised position value.
	# ----------------------------------------------------------------------------
	calc_positions() {
		case "$sec_pos" in
		left)
			sec_pos_xy="0x0"
			pri_pos_xy="${sec_width}x0"
			;;
		right)
			pri_pos_xy="0x0"
			sec_pos_xy="${pri_width}x0"
			;;
		top)
			pri_pos_xy="0x${sec_height}"
			sec_pos_xy="$(((pri_width - sec_width) / 2))x0"
			;;
		bottom)
			pri_pos_xy="0x0"
			sec_pos_xy="0x${pri_height}"
			;;
		*)
			print_error "Unknown secondary monitor position: $sec_pos"
			return 1
			;;
		esac

		#? Only compute tertiary position when a connector is configured
		case "${ter_name:-}" in
		"") ;;
		*)
			case "$ter_pos" in
			left)
				ter_pos_xy="0x0"
				#> Shift primary and secondary right by ter_width
				pri_pos_xy="${ter_width}x${pri_pos_xy#*x}"
				sec_pos_xy="${ter_width}x${sec_pos_xy#*x}"
				;;
			right)
				ter_pos_xy="${pri_width}x0"
				;;
			top)
				ter_pos_xy="0x0"
				pri_pos_xy="${pri_pos_xy%%x*}x${ter_height}"
				sec_pos_xy="${sec_pos_xy%%x*}x${ter_height}"
				;;
			bottom)
				ter_pos_xy="0x${pri_height}"
				;;
			*)
				print_error "Unknown tertiary monitor position: $ter_pos"
				return 1
				;;
			esac
			;;
		esac
	}

	# ----------------------------------------------------------------------------
	# apply
	# ----------------------------------------------------------------------------
	# Queries current monitor positions via hyprctl, compares them against the
	# desired layout, and rewrites hyprland.conf + reloads only when a change is
	# needed.
	# ----------------------------------------------------------------------------
	apply() {
		calc_positions || return 1

		pri_res="$(build_res "$pri_name" "$pri_width" "$pri_height" "$pri_rate")"
		sec_res="$(build_res "$sec_name" "$sec_width" "$sec_height" "$sec_rate")"

		pri_current="$(hyprctl monitors | awk '/Monitor '"$pri_name"'/{found=1} found && /at /{print $3; exit}')"
		sec_current="$(hyprctl monitors | awk '/Monitor '"$sec_name"'/{found=1} found && /at /{print $3; exit}')"

		_needs_reload=0
		case "$pri_current" in
		"$pri_pos_xy") ;;
		*) _needs_reload=1 ;;
		esac
		case "$sec_current" in
		"$sec_pos_xy") ;;
		*) _needs_reload=1 ;;
		esac

		case "$_needs_reload" in
		1)
			hyprctl keyword monitor "$pri_name, ${pri_res}, ${pri_pos_xy}, 1"
			hyprctl keyword monitor "$sec_name, ${sec_res}, ${sec_pos_xy}, 1"

			case "${ter_name:-}" in
			"") ;;
			*)
				ter_res="$(build_res "$ter_name" "$ter_width" "$ter_height" "$ter_rate")"
				hyprctl keyword monitor "$ter_name, ${ter_res}, ${ter_pos_xy}, 1"
				;;
			esac
			;;
		esac
	}

	apply
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
		esac
	}

	# ----------------------------------------------------------------------------
	# start_daemon
	# ----------------------------------------------------------------------------
	# Launches tailscaled in the background when no running instance is detected.
	# Waits briefly for the socket to become available before continuing.
	# ----------------------------------------------------------------------------
	start_daemon() {
		case "$(pgrep tailscaled 2>/dev/null)" in
		"")
			#> Start daemon and redirect its output to a log file
			sudo tailscaled --state=/var/lib/tailscale/tailscaled.state \
				>/tmp/tailscaled.log 2>&1 &
			sleep 2 #? Allow the daemon socket time to initialise
			;;
		esac
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
		case "$verbosity" in
		quiet) ;;
		*)
			print_success "Tailscale already connected"
			tailscale status
			;;
		esac
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
	for pkg in $adhoc_packages; do
		bin="$pkg"
		case "$pkg" in
        wl-clipboard) bin="wl-copy" ;;
        *) bin="$pkg" ;;
        esac
		case "$(command -v "$bin" 2>/dev/null)" in
		"") NIXPKGS_ALLOW_UNFREE=1 nix profile add "nixpkgs#$pkg" ;;
		esac
	done
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
#   --no-recurse  Reserved; currently unused
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
		*) clip_paths="$clip_paths $1" ;;
		esac
		shift
	done

	[ -z "$clip_paths" ] && clip_paths="."

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

		#> Resolve relative paths — check $HOME first, then CWD
		case "$target" in
		/*) ;;
		*)
			if [ -e "$HOME/$target" ]; then
				target="$HOME/$target"
			elif [ -e "./$target" ]; then
				target="./$target"
			fi
			;;
		esac

		if [ -f "$target" ]; then
			#> Prompt for individual file inclusion
			gum confirm "Include $target?" </dev/tty >/dev/tty 2>&1
			exit_code=$?
			case "$exit_code" in
			0) printf "%s\n" "$target" ;; #? Confirmed — emit path
			130)
				print_warn "clip: cancelled"
				return 1
				;;
			*) ;; #? Declined — emit nothing
			esac

		elif [ -d "$target" ]; then
			#> Prompt for directory handling strategy
			choice="$(gum choose \
				--header "Directory: $target" \
				"all" "recurse" "skip" \
				</dev/tty)"
			exit_code=$?
			case "${exit_code:-0}" in
			130)
				print_warn "clip: cancelled"
				return 1
				;;
			esac

			case "$choice" in
			all)
				#> Emit every file under the directory recursively
				fd_args="--type file --hidden"
				[ "$no_ignore" = "1" ] && fd_args="$fd_args --no-ignore"
				# shellcheck disable=SC2086
				fd $fd_args . "$target"
				;;
			recurse)
				#> Inspect each immediate entry individually
				fd_args="--hidden --max-depth 1"
				[ "$no_ignore" = "1" ] && fd_args="$fd_args --no-ignore"
				_recurse_tmp="$(mktemp)"
				# shellcheck disable=SC2086
				fd $fd_args . "$target" >"$_recurse_tmp"
				while IFS= read -r item; do
					collect_files "$item"
				done <"$_recurse_tmp"
				rm -f "$_recurse_tmp"
				;;
			skip | *) ;;
			esac

		else
			print_error "clip: not found: $target"
		fi
	}

	# ── Collect selected file paths ────────────────────────────────────────
	#> Accumulate all emitted paths into a temp file to avoid subshell scoping
	selected=""
	_collect_tmp="$(mktemp)"
	for clip_path in $clip_paths; do
		collect_files "$clip_path" >>"$_collect_tmp"
	done

	#> Read collected paths back into $selected from the temp file
	while IFS= read -r file; do
		selected="$(printf "%s\n%s" "$selected" "$file")"
	done <"$_collect_tmp"
	rm -f "$_collect_tmp"

	#> Strip blank lines introduced by the accumulation pattern
	selected="$(printf "%s" "$selected" | sed '/^$/d')"

	case "$selected" in
	"")
		print_error "clip: nothing selected"
		return 1
		;;
	esac

	# ── Build clipboard content ────────────────────────────────────────────
	file_count="$(printf "%s\n" "$selected" | wc -l)"
	printf "INFO Building content from %s file(s)...\n" "$file_count" >/dev/tty

	#> Write $selected to a temp file so the while-read loop runs in the
	#  current shell (piping would create a subshell, losing $content)
	content=""
	_content_tmp="$(mktemp)"
	printf "%s\n" "$selected" >"$_content_tmp"

	while IFS= read -r file; do
		case "$verbosity" in
		verbose) printf "INFO   adding %s\n" "$file" >/dev/tty ;;
		debug) printf "  adding %s\n" "$file" >/dev/tty ;;
		esac
		#> Wrap each file in a fenced code block with its path as a header
		content="$(printf '%s```\n# %s\n%s\n```\n\n' \
			"$content" "$file" "$(cat "$file")")"
	done <"$_content_tmp"
	rm -f "$_content_tmp"

	printf "%s" "$content" | wl-copy
	printf "INFO clip: copied %s file(s) to clipboard\n" "$file_count" >/dev/tty
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
	esac
}

# ── Remote Helix + tmux workflow ──────────────────────────────────────────────

# ------------------------------------------------------------------------------
# push-hx
# ------------------------------------------------------------------------------
# Syncs local ~/.config/helix to craole@preci:~/.config/helix (one-way).
# ------------------------------------------------------------------------------
push-hx() {
	case "$(command -v rsync 2>/dev/null)" in
	"")
		# Ensure rsync is available
		nix profile add "nixpkgs#rsync" >/dev/null 2>&1
		;;
	esac

	rsync -av --delete ~/.config/helix/ craole@preci:~/.config/helix/ || {
		print_error "push-hx: rsync failed"
		return 1
	}

	print_success "push-hx: synced Helix config to prec"
	# Ensure tmux is available (on local machine)
	case "$(command -v tmux 2>/dev/null)" in
	"") nix profile add "nixpkgs#tmux" >/dev/null 2>&1 ;;
	esac
}

# ------------------------------------------------------------------------------
# dev
# ------------------------------------------------------------------------------
# One-command remote dev entrypoint:
#   1. Sync local Helix config to prec (push-hx)
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

	case "$no_sync" in
	0) push-hx ;;
	*) ;;
	esac

	# Inline tmux attach/create logic (works on remote without extra setup)
	ssh craole@preci -t "tmux attach-session -t dots 2>/dev/null || tmux new-session -s dots"
} && export -f push-hx dev

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
		case "$command" in
		monitors) setup_monitors ;;
		tailscale) setup_tailscale ;;
		utilities) setup_utilities ;;
		rust) setup_rust ;;
		tmux) setup_tmux ;;
		all)
			#~@ Full setup sequence
			setup_monitors
			setup_tailscale
			setup_utilities
			setup_rust
		  setup_tmux
			;;
		esac
	}

	case "$verbosity" in
	dry)
		#> Preview only — print intent without side effects
		printf "Would run: %s\n" "$command"
		printf "  primary:    %s  %sx%s@%s\n" "$pri_name" "$pri_width" "$pri_height" "$pri_rate"
		printf "  secondary:  %s  %sx%s@%s  pos=%s\n" \
			"$sec_name" "$sec_width" "$sec_height" "$sec_rate" "$sec_pos"
		case "${ter_name:-}" in
		"") printf "  tertiary:   (disabled)\n" ;;
		*) printf "  tertiary:   %s  %sx%s@%s  pos=%s\n" \
			"$ter_name" "$ter_width" "$ter_height" "$ter_rate" "$ter_pos" ;;
		esac
		;;
	quiet)
		#> Suppress all output by redirecting stdout and stderr
		run >/dev/null 2>&1
		;;
	info)
		run
		;;
	verbose)
		#> Trace each command as the shell expands it
		set -x
		run
		set +x
		;;
	esac
}

# ── Entry Point ───────────────────────────────────────────────────────────────

# ------------------------------------------------------------------------------
# main "$@"
# ------------------------------------------------------------------------------
# Top-level entry point. Runs configure → parse_arguments → execute in order,
# forwarding all script arguments to parse_arguments.
# ------------------------------------------------------------------------------
main() {
	configure
	parse_arguments "$@"
	execute
} && main "$@"
