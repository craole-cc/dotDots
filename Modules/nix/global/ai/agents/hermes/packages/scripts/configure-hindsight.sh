#!/bin/sh
set -eu

: "${HERMES_HOME:?HERMES_HOME not set}"
: "${HINDSIGHT_MODE:?HINDSIGHT_MODE not set}"
: "${HINDSIGHT_API_URL:?HINDSIGHT_API_URL not set}"
: "${HINDSIGHT_BANK_ID:?HINDSIGHT_BANK_ID not set}"
: "${HINDSIGHT_RECALL_BUDGET:?HINDSIGHT_RECALL_BUDGET not set}"

case "${1:-}" in
  "" | --force) ;;
  *)
    printf '%s\n' "Usage: configure-hindsight [--force]" >&2
    exit 64
    ;;
esac

config_dir="${HERMES_HOME}/hindsight"
config_file="${config_dir}/config.json"

if [ -e "${config_file}" ] && [ "${1:-}" != "--force" ]; then
  printf '%s\n' "Refusing to overwrite ${config_file}; rerun with --force." >&2
  exit 1
fi

umask 077
mkdir -p "${config_dir}"
tmp_file="${config_file}.tmp.$$"
trap 'rm -f "${tmp_file}"' EXIT HUP INT TERM

cat > "${tmp_file}" << EOF
{
  "mode": "${HINDSIGHT_MODE}",
  "api_url": "${HINDSIGHT_API_URL}",
  "bank_id": "${HINDSIGHT_BANK_ID}",
  "memory_mode": "hybrid",
  "auto_retain": true,
  "auto_recall": true,
  "retain_async": true,
  "retain_source": "hermes",
  "recall_budget": "${HINDSIGHT_RECALL_BUDGET}",
  "recall_types": "observation,world,experience"
}
EOF

mv "${tmp_file}" "${config_file}"
hermes config set memory.provider hindsight
printf '%s\n' "Configured Hermes Hindsight external memory at ${HINDSIGHT_API_URL} (bank: ${HINDSIGHT_BANK_ID})."
