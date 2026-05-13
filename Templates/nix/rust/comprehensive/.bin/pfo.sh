#!/bin/sh
set -eu

has_cmd() {
	command -v "$1" >/dev/null 2>&1
}

say_info() {
	if has_cmd print-info; then
		print-info "$1"
	else
		printf '%s\n' "$1"
	fi
}

say_success() {
	if has_cmd print-success; then
		print-success "$1"
	else
		printf 'OK: %s\n' "$1"
	fi
}

say_warn() {
	if has_cmd print-warning; then
		print-warning "$1"
	else
		printf 'WARN: %s\n' "$1"
	fi
}

say_error() {
	if has_cmd print-error; then
		print-error "$1"
	else
		printf 'ERROR: %s\n' "$1" >&2
	fi
}

print_kv() {
	printf '  %-22s %s\n' "$1" "${2:-unknown}"
}

print_json_var() {
	name="$1"
	value="${2-}"

	if [ -z "${value}" ]; then
		say_warn "$name is unset or empty"
		return 0
	fi

	if printf '%s\n' "$value" | jq . >/dev/null 2>&1; then
		printf '%s\n' "$value" | jq .
	else
		say_error "$name is not valid JSON"
		printf '--- raw %s ---\n%s\n' "$name" "$value" >&2
		return 1
	fi
}

check_cmd() {
	if has_cmd "$1"; then
		say_success "$1 -> $(command -v "$1")"
	else
		say_warn "$1 not in PATH"
	fi
}

say_info "Shell Identity"
print_kv "Name" "${DEVSHELL_NAME-}"
print_kv "Project" "${PROJECT_NAME-}"
print_kv "Path" "${PROJECT_PATH-}"

say_info "Raw Variant"
print_json_var "DEVSHELL_RAW" "${DEVSHELL_RAW-}"

say_info "Normalized Variant"
print_json_var "DEVSHELL" "${DEVSHELL-}" || true

say_info "AI Config"
print_json_var "DEVSHELL_AI" "${DEVSHELL_AI-}" || true

say_info "Rust Config"
print_json_var "DEVSHELL_RUST" "${DEVSHELL_RUST-}" || true

say_info "AI Binaries"
check_cmd codex
check_cmd claude
check_cmd hermes
check_cmd openclaw
