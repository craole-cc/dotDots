#!/bin/sh
#shellcheck enable=all
set -eu

: "${HINDSIGHT_RUNTIME_KIND:?HINDSIGHT_RUNTIME_KIND not set}"

case "${HINDSIGHT_RUNTIME_KIND}" in
native)
  : "${HINDSIGHT_SESSION:?HINDSIGHT_SESSION not set}"
  if ! tmux has-session -t "${HINDSIGHT_SESSION}" 2> /dev/null; then
    exit 0
  fi

  tmux send-keys -t "${HINDSIGHT_SESSION}" C-c
  i=0
  while [ "$i" -lt 10 ] && tmux has-session -t "${HINDSIGHT_SESSION}" 2> /dev/null; do
    i=$((i + 1))
    sleep 1
  done

  if tmux has-session -t "${HINDSIGHT_SESSION}" 2> /dev/null; then
    tmux kill-session -t "${HINDSIGHT_SESSION}"
  fi
  ;;
podman|docker)
  : "${HINDSIGHT_COMPOSE_FILE:?HINDSIGHT_COMPOSE_FILE not set}"
  : "${HINDSIGHT_COMPOSE_PROJECT:?HINDSIGHT_COMPOSE_PROJECT not set}"
  : "${HINDSIGHT_CONTAINER_RUNTIME:?HINDSIGHT_CONTAINER_RUNTIME not set}"

  "${HINDSIGHT_CONTAINER_RUNTIME}" compose \
    -p "${HINDSIGHT_COMPOSE_PROJECT}" \
    -f "${HINDSIGHT_COMPOSE_FILE}" down
  ;;
*)
  printf '%s\n' "Unsupported Hindsight runtime: ${HINDSIGHT_RUNTIME_KIND}" >&2
  exit 1
  ;;
esac
