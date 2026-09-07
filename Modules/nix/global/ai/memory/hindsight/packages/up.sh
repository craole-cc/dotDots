#!/bin/sh
#shellcheck enable=all
set -eu

: "${HINDSIGHT_SECRETS_FILE:?HINDSIGHT_SECRETS_FILE not set}"
: "${HINDSIGHT_COMPOSE_FILE:?HINDSIGHT_COMPOSE_FILE not set}"
: "${HINDSIGHT_COMPOSE_PROJECT:?HINDSIGHT_COMPOSE_PROJECT not set}"
: "${HINDSIGHT_CONTAINER_NAME:?HINDSIGHT_CONTAINER_NAME not set}"

if ! docker info > /dev/null 2>&1; then
  gum log \
    --level error \
    "Docker daemon is unavailable; start the host Docker service before Hindsight."
  exit 1
fi

if [ ! -r "${HINDSIGHT_SECRETS_FILE}" ]; then
  gum log \
    --level error \
    "Hindsight secrets file is not readable: ${HINDSIGHT_SECRETS_FILE}"
  exit 1
fi

# shellcheck disable=SC1090
. "${HINDSIGHT_SECRETS_FILE}"

case "${HINDSIGHT_LLM_BACKEND:-openrouter}" in
openrouter)
  : "${HINDSIGHT_OPENROUTER_API_KEY:?HINDSIGHT_OPENROUTER_API_KEY is required in ${HINDSIGHT_SECRETS_FILE}}"
  HINDSIGHT_API_LLM_API_KEY="${HINDSIGHT_OPENROUTER_API_KEY}"
  ;;
*)
  gum log \
    --level error \
    "Unsupported Hindsight LLM backend: ${HINDSIGHT_LLM_BACKEND}"
  exit 1
  ;;
esac
export HINDSIGHT_API_LLM_API_KEY

docker compose \
  -p "${HINDSIGHT_COMPOSE_PROJECT}" \
  -f "${HINDSIGHT_COMPOSE_FILE}" up -d

gum log --level info "Waiting for Hindsight to become healthy..."
attempts=30
status="unknown"
i=0
while [ "$i" -lt "$attempts" ]; do
  status=$(
    docker inspect \
      -f '{{.State.Health.Status}}' \
      "${HINDSIGHT_CONTAINER_NAME}" 2> /dev/null \
      || echo "unknown"
  )
  [ "${status}" = "healthy" ] && break
  i=$((i + 1))
  sleep 2
done

if [ "${status}" != "healthy" ]; then
  gum log \
    --level warn \
    "Hindsight did not report healthy after $((attempts * 2))s (last status: ${status})"
else
  gum log --level info "Hindsight is healthy."
fi

docker compose \
  -p "${HINDSIGHT_COMPOSE_PROJECT}" \
  -f "${HINDSIGHT_COMPOSE_FILE}" ps
