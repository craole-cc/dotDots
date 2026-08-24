#!/bin/sh
#shellcheck enable=all
set -eu

: "${HINDSIGHT_CONTAINER_NAME:?HINDSIGHT_CONTAINER_NAME not set}"

exec docker logs -f "${HINDSIGHT_CONTAINER_NAME}"
