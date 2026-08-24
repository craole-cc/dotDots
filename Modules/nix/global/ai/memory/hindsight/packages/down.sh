#!/bin/sh
#shellcheck enable=all
set -eu

: "${HINDSIGHT_SECRETS_FILE:?HINDSIGHT_SECRETS_FILE not set}"
: "${HINDSIGHT_COMPOSE_FILE:?HINDSIGHT_COMPOSE_FILE not set}"
: "${HINDSIGHT_COMPOSE_PROJECT:?HINDSIGHT_COMPOSE_PROJECT not set}"

if [ -r "${HINDSIGHT_SECRETS_FILE}" ]; then
  set -a
  # shellcheck disable=SC1090
  . "${HINDSIGHT_SECRETS_FILE}"
  set +a
fi

docker compose \
  -p "${HINDSIGHT_COMPOSE_PROJECT}" \
  -f "${HINDSIGHT_COMPOSE_FILE}" down
