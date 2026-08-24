#!/bin/sh
#shellcheck enable=all
set -eu

: "${HINDSIGHT_SECRETS_FILE:?HINDSIGHT_SECRETS_FILE not set}"
: "${HINDSIGHT_DATA_DIR:?HINDSIGHT_DATA_DIR not set}"
: "${HINDSIGHT_COMPOSE_FILE:?HINDSIGHT_COMPOSE_FILE not set}"

if [ ! -r "${HINDSIGHT_SECRETS_FILE}" ]; then
  gum log --level error "Hindsight secrets file is not readable: ${HINDSIGHT_SECRETS_FILE}"
  exit 1
fi

set -a
# shellcheck disable=SC1090
. "${HINDSIGHT_SECRETS_FILE}"
set +a

: "${HINDSIGHT_API_LLM_API_KEY:?HINDSIGHT_API_LLM_API_KEY is required}"

mkdir -p "${HINDSIGHT_DATA_DIR}"
docker compose -f "${HINDSIGHT_COMPOSE_FILE}" up -d
gum log --level info "Hindsight starting..."
sleep 5
docker compose -f "${HINDSIGHT_COMPOSE_FILE}" ps
