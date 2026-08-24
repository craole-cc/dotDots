#!/bin/sh
#shellcheck enable=all
set -eu

: "${HINDSIGHT_CONTAINER_NAME:?HINDSIGHT_CONTAINER_NAME not set}"

bank_id="${1:?Usage: hindsight-bank-create <bank_id> <config.json>}"
config_file="${2:?Usage: hindsight-bank-create <bank_id> <config.json>}"

test -f "${config_file}"
docker exec \
  -i "${HINDSIGHT_CONTAINER_NAME}" hindsight-api bank create \
  --bank-id "${bank_id}" \
  --config /dev/stdin <"${config_file}"
