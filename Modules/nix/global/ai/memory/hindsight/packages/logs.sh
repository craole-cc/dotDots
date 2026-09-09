#!/bin/sh
#shellcheck enable=all
set -eu

: "${HINDSIGHT_RUNTIME_KIND:?HINDSIGHT_RUNTIME_KIND not set}"

case "${HINDSIGHT_RUNTIME_KIND}" in
native)
  : "${HINDSIGHT_SESSION:?HINDSIGHT_SESSION not set}"
  if ! tmux has-session -t "${HINDSIGHT_SESSION}" 2> /dev/null; then
    printf '%s\n' "Hindsight tmux session '${HINDSIGHT_SESSION}' is not running." >&2
    exit 1
  fi
  exec tmux attach-session -t "${HINDSIGHT_SESSION}"
  ;;
podman|docker)
  : "${HINDSIGHT_CONTAINER_NAME:?HINDSIGHT_CONTAINER_NAME not set}"
  : "${HINDSIGHT_CONTAINER_RUNTIME:?HINDSIGHT_CONTAINER_RUNTIME not set}"
  exec "${HINDSIGHT_CONTAINER_RUNTIME}" logs -f "${HINDSIGHT_CONTAINER_NAME}"
  ;;
*)
  printf '%s\n' "Unsupported Hindsight runtime: ${HINDSIGHT_RUNTIME_KIND}" >&2
  exit 1
  ;;
esac
