#!/bin/sh
#shellcheck enable=all
set -eu

: "${HINDSIGHT_API_URL:?HINDSIGHT_API_URL not set}"

curl -fsS "${HINDSIGHT_API_URL}/v1/default/banks" | jq .
