#!/bin/sh
#shellcheck enable=all
set -eu

: "${HINDSIGHT_SECRETS_FILE:?HINDSIGHT_SECRETS_FILE not set}"
: "${HINDSIGHT_RUNTIME_KIND:?HINDSIGHT_RUNTIME_KIND not set}"

if hindsight-status > /dev/null 2>&1; then
  gum log --level info "Hindsight is already healthy at ${HINDSIGHT_API_URL}"
  exit 0
fi

if [ ! -r "${HINDSIGHT_SECRETS_FILE}" ]; then
  gum log --level error "Hindsight secrets file is not readable: ${HINDSIGHT_SECRETS_FILE}"
  exit 1
fi

native_log=""

case "${HINDSIGHT_RUNTIME_KIND}" in
native)
  : "${HINDSIGHT_NATIVE_RUNTIME:?HINDSIGHT_NATIVE_RUNTIME not set}"
  : "${HINDSIGHT_SESSION:?HINDSIGHT_SESSION not set}"
  : "${HINDSIGHT_DATA_DIR:?HINDSIGHT_DATA_DIR not set}"
  : "${HINDSIGHT_CACHE_DIR:?HINDSIGHT_CACHE_DIR not set}"

  if tmux has-session -t "${HINDSIGHT_SESSION}" 2> /dev/null; then
    tmux kill-session -t "${HINDSIGHT_SESSION}" || true
  fi

  native_log="${HINDSIGHT_DATA_DIR}/service.log"
  mkdir -p "${HINDSIGHT_DATA_DIR}"
  : > "${native_log}"

  # OmniRoute may already own the tmux server, whose environment predates
  # this shell's Hindsight initialization. Pass all non-secret runtime
  # configuration explicitly; the native service reads its API key directly
  # from HINDSIGHT_SECRETS_FILE inside the new session. Persist stdout/stderr
  # so an early process exit can be surfaced instead of looking like a
  # five-minute health timeout.
  tmux new-session -d \
    -s "${HINDSIGHT_SESSION}" \
    -e "HINDSIGHT_SECRETS_FILE=${HINDSIGHT_SECRETS_FILE}" \
    -e "HINDSIGHT_DATA_DIR=${HINDSIGHT_DATA_DIR}" \
    -e "HINDSIGHT_CACHE_DIR=${HINDSIGHT_CACHE_DIR}" \
    -e "HINDSIGHT_BIND_ADDRESS=${HINDSIGHT_BIND_ADDRESS}" \
    -e "HINDSIGHT_API_PORT=${HINDSIGHT_API_PORT}" \
    -e "HINDSIGHT_API_WORKER_ID=${HINDSIGHT_API_WORKER_ID:-Hindsight-${HOSTNAME:-local}}" \
    -e "HINDSIGHT_LLM_BACKEND=${HINDSIGHT_LLM_BACKEND}" \
    -e "HINDSIGHT_LLM_BASE_URL=${HINDSIGHT_LLM_BASE_URL}" \
    -e "HINDSIGHT_LLM_MODEL=${HINDSIGHT_LLM_MODEL}" \
    -e "HINDSIGHT_REFLECT_LLM_MODEL=${HINDSIGHT_REFLECT_LLM_MODEL}" \
    "exec \"${HINDSIGHT_NATIVE_RUNTIME}\" >>\"${native_log}\" 2>&1"
  ;;
podman|docker)
  : "${HINDSIGHT_COMPOSE_FILE:?HINDSIGHT_COMPOSE_FILE not set}"
  : "${HINDSIGHT_COMPOSE_PROJECT:?HINDSIGHT_COMPOSE_PROJECT not set}"
  : "${HINDSIGHT_CONTAINER_RUNTIME:?HINDSIGHT_CONTAINER_RUNTIME not set}"

  # shellcheck disable=SC1090
  . "${HINDSIGHT_SECRETS_FILE}"

  case "${HINDSIGHT_LLM_BACKEND:-openrouter}" in
  openrouter)
    key="${OPENROUTER_API_KEY:-${HINDSIGHT_OPENROUTER_API_KEY:-}}"
    : "${key:?OPENROUTER_API_KEY is required in ${HINDSIGHT_SECRETS_FILE}}"
    ;;
  groq)
    key="${GROQ_API_KEY:-${HINDSIGHT_GROQ_API_KEY:-}}"
    : "${key:?GROQ_API_KEY is required in ${HINDSIGHT_SECRETS_FILE}}"
    ;;
  *)
    gum log --level error "Unsupported Hindsight LLM backend: ${HINDSIGHT_LLM_BACKEND}"
    exit 1
    ;;
  esac

  export HINDSIGHT_API_LLM_API_KEY="${key}"
  unset key

  case "${HINDSIGHT_COMPOSE_FILE}" in
  /nix/store/*-source/*)
    gum log --level error "Hindsight Compose manifest must be a packaged store artifact: ${HINDSIGHT_COMPOSE_FILE}"
    exit 1
    ;;
  esac

  if [ ! -f "${HINDSIGHT_COMPOSE_FILE}" ]; then
    gum log --level error "Hindsight Compose manifest is missing: ${HINDSIGHT_COMPOSE_FILE}"
    exit 1
  fi

  if [ "${HINDSIGHT_RUNTIME_KIND}" = "podman" ]; then
    user_policy="${XDG_CONFIG_HOME:-${HOME}/.config}/containers/policy.json"
    if [ ! -r "${user_policy}" ] && [ ! -r /etc/containers/policy.json ]; then
      : "${CONTAINERS_POLICY_JSON:?CONTAINERS_POLICY_JSON not set}"
      install -Dm644 "${CONTAINERS_POLICY_JSON}" "${user_policy}"
      gum log --level info "Installed Podman policy at ${user_policy}"
    fi
    unset user_policy
  fi

  if ! runtime_info="$("${HINDSIGHT_CONTAINER_RUNTIME}" info 2>&1)"; then
    gum log --level error "${HINDSIGHT_RUNTIME_KIND} is unavailable for Hindsight."
    if [ -n "${runtime_info}" ]; then
      printf '%s\n' '----- Container runtime probe -----' >&2
      printf '%s\n' "${runtime_info}" >&2
      printf '%s\n' '-----------------------------------' >&2
    fi
    exit 1
  fi
  unset runtime_info

  "${HINDSIGHT_CONTAINER_RUNTIME}" compose \
    -p "${HINDSIGHT_COMPOSE_PROJECT}" \
    -f "${HINDSIGHT_COMPOSE_FILE}" up -d
  ;;
*)
  gum log --level error "Unsupported Hindsight runtime: ${HINDSIGHT_RUNTIME_KIND}"
  exit 1
  ;;
esac

gum log --level info "Waiting for Hindsight to become healthy..."
attempts=150
i=0
while [ "$i" -lt "$attempts" ]; do
  if hindsight-status > /dev/null 2>&1; then
    gum log --level info "Hindsight is healthy."
    exit 0
  fi

  if [ "${HINDSIGHT_RUNTIME_KIND}" = "native" ] \
    && ! tmux has-session -t "${HINDSIGHT_SESSION}" 2> /dev/null; then
    gum log --level error "Hindsight native process exited before becoming healthy."
    if [ -s "${native_log}" ]; then
      printf '%s\n' '----- Hindsight startup log -----' >&2
      tail -n 120 "${native_log}" >&2
      printf '%s\n' '---------------------------------' >&2
    else
      printf '%s\n' "No startup output was captured in ${native_log}" >&2
    fi
    exit 1
  fi

  i=$((i + 1))
  sleep 2
done

if [ "${HINDSIGHT_RUNTIME_KIND}" = "native" ]; then
  gum log --level warn "Hindsight is still running but did not become healthy after $((attempts * 2))s"
  if [ -s "${native_log}" ]; then
    printf '%s\n' '----- Hindsight startup log (tail) -----' >&2
    tail -n 80 "${native_log}" >&2
    printf '%s\n' '----------------------------------------' >&2
  fi
else
  gum log --level warn "Hindsight did not become healthy after $((attempts * 2))s"
fi
exit 1
