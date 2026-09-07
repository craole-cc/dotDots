#!/bin/sh
#shellcheck enable=all
set -eu

: "${HINDSIGHT_IMAGE:?HINDSIGHT_IMAGE not set}"
: "${HINDSIGHT_COMPOSE_PROJECT:?HINDSIGHT_COMPOSE_PROJECT not set}"

printf '%s\n' "Hindsight image: ${HINDSIGHT_IMAGE}"
if size=$(docker image inspect --format '{{.Size}}' "${HINDSIGHT_IMAGE}" 2> /dev/null); then
  printf 'Image size: %s\n' "$(numfmt --to=iec "${size}" 2> /dev/null || printf '%s bytes' "${size}")"
  docker image inspect \
    --format 'Repo digests: {{json .RepoDigests}}' \
    "${HINDSIGHT_IMAGE}"
else
  printf '%s\n' 'Image is not currently present locally.'
fi

printf '\n%s\n' "Hindsight volumes for ${HINDSIGHT_COMPOSE_PROJECT}:"
docker volume ls \
  --filter "label=com.docker.compose.project=${HINDSIGHT_COMPOSE_PROJECT}"

printf '\n%s\n' 'Docker disk usage:'
docker system df

docker_root=$(docker info --format '{{.DockerRootDir}}' 2> /dev/null || true)
if [ -n "${docker_root}" ]; then
  printf '\nDocker root: %s\n' "${docker_root}"
  df -h "${docker_root}" 2> /dev/null || df -h /
fi
