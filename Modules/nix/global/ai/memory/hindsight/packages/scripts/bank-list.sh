#!/bin/sh
#shellcheck enable=all
set -eu

: "${HINDSIGHT_CONTAINER_NAME:?HINDSIGHT_CONTAINER_NAME not set}"

exec docker exec "${HINDSIGHT_CONTAINER_NAME}" hindsight-api bank list
