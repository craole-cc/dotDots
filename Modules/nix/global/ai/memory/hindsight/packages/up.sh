#!/bin/sh
#shellcheck enable=all
set -eu

: "${HINDSIGHT_SECRETS_FILE:?HINDSIGHT_SECRETS_FILE not set}"
: "${HINDSIGHT_COMPOSE_FILE:?HINDSIGHT_COMPOSE_FILE not set}"
: "${HINDSIGHT_COMPOSE_PROJECT:?HINDSIGHT_COMPOSE_PROJECT not set}"
: "${HINDSIGHT_CONTAINER_NAME:?HINDSIGHT_CONTAINER_NAME not set}"
: "${HINDSIGHT_CONTAINER_RUNTIME:?HINDSIGHT_CONTAINER_RUNTIME not set}"

case "${HINDSIGHT_COMPOSE_FILE}" in
/nix/store/*-source/*)
  gum log \
    --level error \
    "Hindsight Compose manifest must be a packaged store artifact: ${HINDSIGHT_COMPOSE_FILE}"
  exit 1
  ;;
esac

if [ ! -f "${HINDSIGHT_COMPOSE_FILE}" ]; then
  gum log \
    --level error \
    "Hindsight Compose manifest is missing: ${HINDSIGHT_COMPOSE_FILE}"
  exit 1
fi

# Podman before v6 does not honor CONTAINERS_POLICY_JSON, but still requires
# policy.json at its standard user/system locations. Keep the devShell
# self-contained by installing the packaged policy only when neither exists.
if [ "${HINDSIGHT_CONTAINER_RUNTIME}" = "podman" ]; then
  user_policy="${XDG_CONFIG_HOME:-${HOME}/.config}/containers/policy.json"
  if [ ! -r "${user_policy}" ] && [ ! -r /etc/containers/policy.json ]; then
    : "${CONTAINERS_POLICY_JSON:?CONTAINERS_POLICY_JSON not set}"
    install -Dm644 "${CONTAINERS_POLICY_JSON}" "${user_policy}"
    gum log --level info "Installed Podman policy at ${user_policy}"
  fi
  unset user_policy
fi

if ! "${HINDSIGHT_CONTAINER_RUNTIME}" info > /dev/null 2>&1; then
  gum log \
    --level error \
    "${HINDSIGHT_CONTAINER_RUNTIME} is unavailable for Hindsight."
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
  key="${OPENROUTER_API_KEY:-${HINDSIGHT_OPENROUTER_API_KEY:-}}"
  : "${key:?OPENROUTER_API_KEY is required in ${HINDSIGHT_SECRETS_FILE}}"
  HINDSIGHT_API_LLM_API_KEY="${key}"
  ;;
groq)
  key="${GROQ_API_KEY:-${HINDSIGHT_GROQ_API_KEY:-}}"
  : "${key:?GROQ_API_KEY is required in ${HINDSIGHT_SECRETS_FILE}}"
  HINDSIGHT_API_LLM_API_KEY="${key}"
  ;;
*)
  gum log \
    --level error \
    "Unsupported Hindsight LLM backend: ${HINDSIGHT_LLM_BACKEND}"
  exit 1
  ;;
esac
export HINDSIGHT_API_LLM_API_KEY
unset key

"${HINDSIGHT_CONTAINER_RUNTIME}" compose \
  -p "${HINDSIGHT_COMPOSE_PROJECT}" \
  -f "${HINDSIGHT_COMPOSE_FILE}" up -d

gum log --level info "Waiting for Hindsight to become healthy..."
attempts=30
status="unknown"
i=0
while [ "$i" -lt "$attempts" ]; do
  status=$(
    "${HINDSIGHT_CONTAINER_RUNTIME}" inspect \
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

"${HINDSIGHT_CONTAINER_RUNTIME}" compose \
  -p "${HINDSIGHT_COMPOSE_PROJECT}" \
  -f "${HINDSIGHT_COMPOSE_FILE}" ps
