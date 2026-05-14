#!/bin/sh
# shellcheck enable=all

set -u

usage() {
	cat <<'EOF'
Usage: cmd ACTION [OPTIONS] COMMAND...

Inspect commands available on PATH.

Actions:
  loc              Print command paths
  src              Show command source with bat if available, otherwise cat
  cp               Copy command source to clipboard

Options:
  -x, --raw        Copy raw source without headers (cp only)
  -h, --help       Show this help text

Examples:
  cmd loc gcp update
  cmd src gcp
  cmd cp gcp update
  cmd cp --raw gcp
EOF
}

find_cmd() {
	command -v "${1}" 2>/dev/null || true
}

parse_args() {
	ACTION=${1:-}
	RAW=0

	case "${ACTION}" in
	'' | -h | --help)
		usage
		return 1
		;;
	loc | src | cp)
		shift
		;;
	*)
		printf 'Unknown action: %s\n' "${ACTION}" >&2
		usage >&2
		return 2
		;;
	esac

	while [ "${#}" -gt 0 ]; do
		case "${1}" in
		-x | --raw)
			RAW=1
			;;
		-h | --help)
			usage
			return 1
			;;
		--)
			shift
			break
			;;
		-*)
			printf 'Unknown option: %s\n' "${1}" >&2
			usage >&2
			return 2
			;;
		*)
			break
			;;
		esac

		shift
	done

	if [ "${#}" -eq 0 ]; then
		printf 'Missing command name.\n' >&2
		usage >&2
		return 2
	fi

	COMMANDS=${*}
	return 0
}

resolve_tools() {
	CMD_BAT=${CMD_BAT:-}
	CMD_CAT=${CMD_CAT:-}
	CMD_CLIP=${CMD_CLIP:-}
	CMD_WL_COPY=${CMD_WL_COPY:-}
	CMD_XCLIP=${CMD_XCLIP:-}
	CMD_PBCOPY=${CMD_PBCOPY:-}

	if [ -z "${CMD_BAT}" ]; then
		CMD_BAT=$(find_cmd bat)
	fi

	if [ -z "${CMD_CAT}" ]; then
		CMD_CAT=$(find_cmd cat)
	fi

	if [ -z "${CMD_CLIP}" ]; then
		CMD_CLIP=$(find_cmd clip)
	fi

	if [ -z "${CMD_WL_COPY}" ]; then
		CMD_WL_COPY=$(find_cmd wl-copy)
	fi

	if [ -z "${CMD_XCLIP}" ]; then
		CMD_XCLIP=$(find_cmd xclip)
	fi

	if [ -z "${CMD_PBCOPY}" ]; then
		CMD_PBCOPY=$(find_cmd pbcopy)
	fi
}

resolve_command() {
	path=$(find_cmd "${1}")

	if [ -z "${path}" ]; then
		printf 'Command not found: %s\n' "${1}" >&2
		return 1
	fi

	printf '%s\n' "${path}"
}

show_source() {
	path=${1}

	if [ -n "${CMD_BAT}" ]; then
		"${CMD_BAT}" "${path}"
	elif [ -n "${CMD_CAT}" ]; then
		"${CMD_CAT}" "${path}"
	else
		printf 'Error: neither bat nor cat was found.\n' >&2
		return 1
	fi
}

copy_output() {
	if [ -n "${CMD_CLIP}" ]; then
		"${CMD_CLIP}"
	elif [ -n "${CMD_WL_COPY}" ]; then
		"${CMD_WL_COPY}"
	elif [ -n "${CMD_XCLIP}" ]; then
		"${CMD_XCLIP}" -selection clipboard
	elif [ -n "${CMD_PBCOPY}" ]; then
		"${CMD_PBCOPY}"
	else
		printf 'Error: no clipboard command found.\n' >&2
		return 1
	fi
}

execute_loc() {
	status=0

	for cmd in ${COMMANDS}; do
		resolve_command "${cmd}" || {
			status=1
			continue
		}
	done

	return "${status}"
}

execute_src() {
	status=0

	for cmd in ${COMMANDS}; do
		path=$(resolve_command "${cmd}") || {
			status=1
			continue
		}

		show_source "${path}" || status=${?}
	done

	return "${status}"
}

execute_cp() {
	status=0
	first=1
	tmp=${TMPDIR:-/tmp}/cmd-cp.$$

	: >"${tmp}" || {
		printf 'Error: could not create temporary file: %s\n' "${tmp}" >&2
		return 1
	}

	for cmd in ${COMMANDS}; do
		path=$(resolve_command "${cmd}") || {
			status=1
			continue
		}

		if [ "${first}" -eq 0 ]; then
			printf '\n\n' >>"${tmp}"
		fi
		first=0

		if [ "${RAW}" -eq 0 ]; then
			printf '# cmd: %s (%s)\n\n' "${cmd}" "${path}" >>"${tmp}"
		fi

		if [ -n "${CMD_CAT}" ]; then
			"${CMD_CAT}" "${path}" >>"${tmp}"
		else
			printf 'Error: cat was not found.\n' >&2
			rm -f "${tmp}"
			return 1
		fi
	done

	copy_output <"${tmp}" || status=${?}
	rm -f "${tmp}"

	return "${status}"
}

execute() {
	resolve_tools

	case "${ACTION}" in
	loc) execute_loc ;;
	src) execute_src ;;
	cp) execute_cp ;;
	*)
		printf 'Unknown action: %s\n' "${ACTION}" >&2
		return 2
		;;
	esac
}

main() {
	parse_args "${@}"
	status=${?}

	case "${status}" in
	0)
		execute
		;;
	1)
		exit 0
		;;
	*)
		exit "${status}"
		;;
	esac
}

main "${@}"
