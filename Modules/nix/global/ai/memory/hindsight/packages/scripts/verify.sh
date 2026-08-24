#!/bin/sh
#shellcheck enable=all
set -eu

: "${HINDSIGHT_API_URL:?HINDSIGHT_API_URL not set}"

curl -fsS "${HINDSIGHT_API_URL}/openapi.json" \
  | jq -e '.paths | type == "object"' > /dev/null

printf 'Hindsight API OpenAPI document is valid at %s\n' "${HINDSIGHT_API_URL}"
