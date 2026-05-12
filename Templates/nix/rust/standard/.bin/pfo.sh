#!/bin/sh
set -eu

print-info "Shell Identity"
printf '  %-22s %s\n' "Name" "${DEVSHELL_NAME:-unknown}"
printf '  %-22s %s\n' "Project" "${PROJECT_NAME:-unknown}"
printf '  %-22s %s\n' "Path" "${PROJECT_PATH:-unknown}"

print-info "Raw Variant"
printf '%s\n' "${DEVSHELL_RAW:-{}}" | jq .

print-info "Normalized Variant"
printf '%s\n' "${DEVSHELL:-{}}" | jq .

print-info "AI Config"
printf '%s\n' "${DEVSHELL_AI:-{}}" | jq .

print-info "Rust Config"
printf '%s\n' "${DEVSHELL_RUST:-{}}" | jq .
