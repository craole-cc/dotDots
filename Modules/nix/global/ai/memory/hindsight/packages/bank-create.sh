#!/bin/sh
#shellcheck enable=all
set -eu

: "${HINDSIGHT_API_URL:?HINDSIGHT_API_URL not set}"

bank_id="${1:?Usage: hindsight-bank-create <bank_id> <config.json>}"
config_file="${2:?Usage: hindsight-bank-create <bank_id> <config.json>}"

test -f "${config_file}"

curl -fsS \
  -X PUT \
  -H 'Content-Type: application/json' \
  --data-binary "@${config_file}" \
  "${HINDSIGHT_API_URL}/v1/default/banks/${bank_id}" |
  jq .
