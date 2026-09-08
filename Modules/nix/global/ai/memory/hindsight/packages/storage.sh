#!/bin/sh
#shellcheck enable=all
set -eu

: "${HINDSIGHT_IMAGE:?HINDSIGHT_IMAGE not set}"
: "${HINDSIGHT_COMPOSE_PROJECT:?HINDSIGHT_COMPOSE_PROJECT not set}"
: "${HINDSIGHT_CONTAINER_RUNTIME:?HINDSIGHT_CONTAINER_RUNTIME not set}"

runtime=${HINDSIGHT_CONTAINER_RUNTIME}
kind=${HINDSIGHT_CONTAINER_RUNTIME_KIND:-}
volume="${HINDSIGHT_COMPOSE_PROJECT}_hindsight-pg0"

printf '%s\n' "Hindsight image: ${HINDSIGHT_IMAGE}"
if size=$("${runtime}" image inspect --format '{{.Size}}' "${HINDSIGHT_IMAGE}" 2> /dev/null); then
  printf 'Image size: %s\n' "$(numfmt --to=iec "${size}" 2> /dev/null || printf '%s bytes' "${size}")"
  "${runtime}" image inspect \
    --format 'Repo digests: {{json .RepoDigests}}' \
    "${HINDSIGHT_IMAGE}"
else
  printf '%s\n' 'Image is not currently present locally.'
fi

printf '\n%s\n' "Hindsight volume for ${HINDSIGHT_COMPOSE_PROJECT}:"
"${runtime}" volume ls --filter "name=${volume}"

printf '\n%s\n' "${kind:-container runtime} disk usage:"
"${runtime}" system df

case "${kind}" in
podman)
  root=$("${runtime}" info --format '{{.Store.GraphRoot}}' 2> /dev/null || true)
  ;;
docker)
  root=$("${runtime}" info --format '{{.DockerRootDir}}' 2> /dev/null || true)
  ;;
*)
  root=""
  ;;
esac

if [ -n "${root}" ]; then
  printf '\nContainer root: %s\n' "${root}"
  df -h "${root}" 2> /dev/null || df -h /
fi
