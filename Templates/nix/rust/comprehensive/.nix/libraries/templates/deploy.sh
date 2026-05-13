#!/bin/sh
# shellcheck enable=all

set -u

usage() {
	cat <<'EOF'
Usage: deploy-templates [OPTIONS]

Deploy template files into the current project root.

Options:
  --force, -f  Overwrite template targets that differ from the source
  --reset, -r  Reset deployed/generated files before deploying templates
  --help,  -h  Show this help text

By default, changed files are left in place and reported as skipped.
EOF
}
find_cmd() { command -v "${1}" 2>/dev/null || true; }

CMD_PRINT_ERROR=${CMD_PRINT_ERROR:-}
CMD_PRINT_SUCCESS=${CMD_PRINT_SUCCESS:-}
CMD_PRINT_WARNING=${CMD_PRINT_WARNING:-}
CMD_PRINT_INFO=${CMD_PRINT_INFO:-}

if [ -z "${CMD_PRINT_ERROR}" ]; then
	CMD_PRINT_ERROR=$(find_cmd print_error)
fi

if [ -z "${CMD_PRINT_SUCCESS}" ]; then
	CMD_PRINT_SUCCESS=$(find_cmd print_success)
fi

if [ -z "${CMD_PRINT_WARNING}" ]; then
	CMD_PRINT_WARNING=$(find_cmd print_warning)
fi

if [ -z "${CMD_PRINT_INFO}" ]; then
	CMD_PRINT_INFO=$(find_cmd print_info)
fi

print_error() {
	if [ -n "${CMD_PRINT_ERROR}" ]; then
		"${CMD_PRINT_ERROR}" "${1}"
	else
		printf 'Error: %s\n' "${1}"
	fi
}

print_success() {
	if [ -n "${CMD_PRINT_SUCCESS}" ]; then
		"${CMD_PRINT_SUCCESS}" "${1}"
	else
		printf '%s\n' "${1}"
	fi
}

print_warning() {
	if [ -n "${CMD_PRINT_WARNING}" ]; then
		"${CMD_PRINT_WARNING}" "${1}"
	else
		printf 'Warning: %s\n' "${1}"
	fi
}

print_info() {
	if [ -n "${CMD_PRINT_INFO}" ]; then
		"${CMD_PRINT_INFO}" "${1}"
	else
		printf '%s\n' "${1}"
	fi
}

parse_args() {
	FORCE=0
	RESET=0

	while [ "${#}" -gt 0 ]; do
		case "${1}" in
		-f | --force) FORCE=1 ;;
		-r | --reset) RESET=1 ;;
		-h | --help)
			usage
			exit 0
			;;
		*)
			print_error "Unknown option: ${1}" >&2
			usage >&2
			exit 1
			;;
		esac

		shift
	done
}

resolve_root() {
	ROOT=${PRJ_ROOT:-${PWD}}
}

reset_before_deploy() {
	if [ "${RESET}" -ne 1 ]; then
		return 0
	fi

	if [ ! -f "${ROOT}/.nix-template-state" ]; then
		print_warning "No .nix-template-state marker found; skipping reset and deploying fresh templates." >&2
		return 0
	fi

	if command -v reset-flake >/dev/null 2>&1; then
		PRJ_ROOT=${ROOT} reset-flake
	else
		print_error "reset-flake command not found on PATH." >&2
		return 1
	fi
}

deploy_entry() {
	template_name=${1}
	full_source=${2}
	preferred_target=${3}
	shift 3

	full_preferred=${ROOT}/${preferred_target}

	if [ ! -f "${full_source}" ]; then
		print_error "Template source ${full_source} is missing." >&2
		return 1
	fi

	mkdir -p "$(dirname "${full_preferred}")"

	existing_target=
	existing_count=0

	for target_line in "${@}"; do
		full_target=${ROOT}/${target_line}

		if [ -f "${full_target}" ]; then
			existing_count=$((existing_count + 1))

			if [ -z "${existing_target}" ] || [ "${full_target}" = "${full_preferred}" ]; then
				existing_target=${full_target}
			fi
		fi
	done

	if [ "${existing_count}" -gt 1 ]; then
		if [ "${FORCE}" -ne 1 ]; then
			print_warning "${template_name}: multiple target files detected; skipping. Re-run with --force to overwrite preferred target." >&2
			return 0
		fi

		print_warning "${template_name}: multiple target files detected; overwriting preferred target only." >&2
	fi

	if [ -n "${existing_target}" ] && [ "${FORCE}" -ne 1 ]; then
		if [ "${existing_target}" = "${full_preferred}" ] && cmp -s "${full_source}" "${full_preferred}"; then
			print_success "${template_name}: already up to date" >&2
		else
			print_warning "${template_name}: existing target detected at ${existing_target}; skipping. Re-run with --force to overwrite ${full_preferred}." >&2
		fi

		return 0
	fi

	if [ "${FORCE}" -eq 1 ]; then
		print_warning "${template_name}: deploying ${full_preferred} (--force)" >&2
	else
		print_success "${template_name}: deploying ${full_preferred}" >&2
	fi

	cp "${full_source}" "${full_preferred}"
	chmod u+w "${full_preferred}" 2>/dev/null || true
}

execute() {
	true
	#__DEPLOY_CONF_CALLS__
}

main() {
	parse_args "${@}"
	resolve_root
	reset_before_deploy
	execute
}

main "${@}"
