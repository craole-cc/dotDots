#!/bin/sh
set -euf

header() { printf '\n\033[1;36m══ %s ══\033[0m\n' "$1"; }
kv() { printf '  \033[1;33m%-22s\033[0m %s\n' "$1" "$2"; }
ok() { printf '  \033[1;32m✔  %-20s\033[0m %s\n' "$1" "$2"; }
miss() { printf '  \033[1;31m✘  %-20s\033[0m (not in PATH)\n' "$1"; }

check_cmd() {
	if command -v "$1" >/dev/null 2>&1; then
		ok "$1" "$(command -v "$1")"
	else
		miss "$1"
	fi
}

header "Shell Identity"
kv "Name" "${DEVSHELL_NAME:-unknown}"
kv "Project" "${PROJECT_NAME:-unknown}"
kv "Path" "${PROJECT_PATH:-unknown}"

header "Raw Variant"
echo "${DEVSHELL_RAW:-{}}" | jq .

header "Normalized Variant"
echo "${DEVSHELL:-{}}" | jq .

header "AI Config"
echo "${DEVSHELL_AI:-{}}" | jq .

header "Rust Config"
echo "${DEVSHELL_RUST:-{}}" | jq .

header "AI Binaries"
check_cmd codex
check_cmd claude
check_cmd hermes
check_cmd openclaw

header "Rust Binaries"
check_cmd rustc
check_cmd cargo
check_cmd rust-analyzer
check_cmd rustfmt

header "Web Binaries"
check_cmd deno
check_cmd pnpm
check_cmd trunk

header "Database Binaries"
check_cmd psql
check_cmd mariadb
check_cmd redis-server
check_cmd sqlite3
