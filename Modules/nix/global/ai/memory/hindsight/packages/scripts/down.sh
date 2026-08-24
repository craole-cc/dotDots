#!/bin/sh
#shellcheck enable=all
set -eu

: "${HINDSIGHT_COMPOSE_FILE:?HINDSIGHT_COMPOSE_FILE not set}"

docker compose -f "${HINDSIGHT_COMPOSE_FILE}" down
