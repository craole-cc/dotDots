#!/bin/sh
#shellcheck enable=all
set -eu

: "${HINDSIGHT_API_URL:?HINDSIGHT_API_URL not set}"

if ! response=$(curl -fsS "${HINDSIGHT_API_URL}/health" 2> /dev/null); then
  gum log \
    --level error \
    "Hindsight is not reachable at ${HINDSIGHT_API_URL}"
  exit 1
fi

printf '%s\n' "${response}"
