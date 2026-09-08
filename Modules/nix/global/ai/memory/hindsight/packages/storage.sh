#!/bin/sh
#shellcheck enable=all
set -eu

: "${HINDSIGHT_RUNTIME_KIND:?HINDSIGHT_RUNTIME_KIND not set}"

case "${HINDSIGHT_RUNTIME_KIND}" in
native)
  : "${HINDSIGHT_DATA_DIR:?HINDSIGHT_DATA_DIR not set}"
  : "${HINDSIGHT_CACHE_DIR:?HINDSIGHT_CACHE_DIR not set}"

  printf '%s\n' "Hindsight data: ${HINDSIGHT_DATA_DIR}"
  du -sh "${HINDSIGHT_DATA_DIR}" 2> /dev/null || printf '%s\n' 'No persistent data yet.'

  printf '\n%s\n' "Hindsight cache: ${HINDSIGHT_CACHE_DIR}"
  du -sh "${HINDSIGHT_CACHE_DIR}" 2> /dev/null || printf '%s\n' 'No cache yet.'
  ;;
podman|docker)
  : "${HINDSIGHT_IMAGE:?HINDSIGHT_IMAGE not set}"
  : "${HINDSIGHT_COMPOSE_PROJECT:?HINDSIGHT_COMPOSE_PROJECT not set}"
  : "${HINDSIGHT_CONTAINER_RUNTIME:?HINDSIGHT_CONTAINER_RUNTIME not set}"

  runtime=${HINDSIGHT_CONTAINER_RUNTIME}
  volume="${HINDSIGHT_COMPOSE_PROJECT}_hindsight-pg0"

  printf '%s\n' "Hindsight image: ${HINDSIGHT_IMAGE}"
  if size=$("${runtime}" image inspect --format '{{.Size}}' "${HINDSIGHT_IMAGE}" 2> /dev/null); then
    printf 'Image size: %s\n' "$(numfmt --to=iec "${size}" 2> /dev/null || printf '%s bytes' "${size}")"
  else
    printf '%s\n' 'Image is not currently present locally.'
  fi

  printf '\n%s\n' "Hindsight volume for ${HINDSIGHT_COMPOSE_PROJECT}:"
  "${runtime}" volume ls --filter "name=${volume}"

  printf '\n%s\n' "${HINDSIGHT_RUNTIME_KIND} disk usage:"
  "${runtime}" system df
  ;;
*)
  printf '%s\n' "Unsupported Hindsight runtime: ${HINDSIGHT_RUNTIME_KIND}" >&2
  exit 1
  ;;
esac
