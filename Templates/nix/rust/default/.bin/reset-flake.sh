#!/bin/sh
# shellcheck enable=all

set -u

usage() {
	cat <<'EOF'
Usage: reset-flake [OPTIONS]

Reset the nearest flake workspace by removing generated configuration files
and transient build/cache directories.

By default, protected project files such as .envrc and .gitignore are kept.

Options:
  --all, -a   Also remove protected project files such as .envrc and .gitignore
  --root DIR  Reset the specified flake root instead of discovering the nearest one
  --help, -h  Show this help text
EOF
}

parse_args() {
	ALL=0
	ROOT_INPUT=${PRJ_ROOT:-}

	while [ "${#}" -gt 0 ]; do
		case "${1}" in
		-a | --all)
			ALL=1
			;;
		--root)
			[ "${#}" -ge 2 ] || {
				printf 'Error: --root requires a directory.\n' >&2
				return 2
			}
			ROOT_INPUT=${2}
			shift
			;;
		-h | --help)
			usage
			return 1
			;;
		*)
			printf 'Unknown option: %s\n' "${1}" >&2
			usage >&2
			return 2
			;;
		esac

		shift
	done

	return 0
}

physical_path() {
	cd "${1}" 2>/dev/null && pwd -P
}

find_nearest_root() {
	dir=$(physical_path "${1}") || return 1

	while [ "${dir}" != "/" ]; do
		if [ -d "${dir}/.nix" ]; then
			printf '%s\n' "${dir}"
			return 0
		fi

		dir=$(dirname "${dir}")
	done

	return 1
}

resolve_root() {
	start=${ROOT_INPUT:-${PWD}}

	ROOT=$(find_nearest_root "${start}") || {
		printf 'Error: could not find a flake root from %s.\n' "${start}" >&2
		printf 'Expected to find a parent directory containing .nix.\n' >&2
		exit 1
	}

	[ -n "${ROOT}" ] || {
		printf 'Error: ROOT is empty.\n' >&2
		exit 1
	}

	[ -d "${ROOT}/.nix" ] || {
		printf 'Error: %s is not a managed flake root; missing .nix directory.\n' "${ROOT}" >&2
		exit 1
	}

	[ -f "${ROOT}/flake.nix" ] || {
		printf 'Error: %s is not a flake root; missing flake.nix.\n' "${ROOT}" >&2
		exit 1
	}
}

remove_path() {
	path=$(printf '%s/%s' "${ROOT}" "${1}")

	if [ -e "${path}" ]; then
		rm -rf "${path}"
		printf 'removed %s\n' "${path}"
	fi
}

dir_is_empty() {
	path=${1}
	first_entry=$(find "${path}" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null || true)

	[ -z "${first_entry}" ]
}

remove_empty_dir() {
	path=$(printf '%s/%s' "${ROOT}" "${1}")

	if [ -d "${path}" ] && dir_is_empty "${path}"; then
		rmdir "${path}" 2>/dev/null || true
	fi
}

remove_transient() {
	remove_path ".direnv"
	remove_path "target"
	remove_path "node_modules"
	remove_path "dist"
	remove_path "build"
	remove_path ".next"
	remove_path ".svelte-kit"
	remove_path "coverage"
	remove_path ".turbo"
	remove_path ".cache"
	remove_path ".parcel-cache"
	remove_path ".vite"
}

remove_conf() {
	remove_path ".cargo/config.toml"
	remove_empty_dir ".cargo"

	remove_path ".markdownlint-cli2.yaml"
	remove_path "markdownlint-cli2.yaml"

	remove_path ".mise.toml"
	remove_path "mise.toml"

	remove_path ".shellcheckrc"
	remove_path "shellcheckrc"

	remove_path ".treefmt.toml"
	remove_path "treefmt.toml"

	remove_path ".trunk.toml"
	remove_path "Trunk.toml"
	remove_path ".trunk.yaml"
	remove_path "Trunk.yaml"
	remove_path ".trunk.json"
	remove_path "Trunk.json"

	remove_path ".rust-analyzer.toml"
	remove_path "rust-analyzer.toml"

	remove_path ".rustfmt.toml"
	remove_path "rustfmt.toml"

	remove_path "rust-toolchain.toml"

	remove_path "deno.jsonc"
	remove_path ".prettierrc"
	remove_path "prettier.config.json"
}

remove_protected() {
	if [ "${ALL}" -ne 1 ]; then
		return 0
	fi

	remove_path ".envrc"
	remove_path ".gitignore"
}

execute() {
	printf 'reset-flake: root = %s\n' "${ROOT}"

	remove_transient
	remove_conf
	remove_protected
}

main() {
	parse_args "${@}"
	status=${?}

	case "${status}" in
	0)
		resolve_root
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
