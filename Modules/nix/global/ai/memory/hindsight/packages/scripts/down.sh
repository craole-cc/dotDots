#!/bin/sh
#shellcheck enable=all
set -eu

: "${HINDSIGHT_COMPOSE_FILE:?HINDSIGHT_COMPOSE_FILE not set}"
: "${HINDSIGHT_COMPOSE_PROJECT:?HINDSIGHT_COMPOSE_PROJECT not set}"

docker compose \
  -p "${HINDSIGHT_COMPOSE_PROJECT}" \
  -f "${HINDSIGHT_COMPOSE_FILE}" down
