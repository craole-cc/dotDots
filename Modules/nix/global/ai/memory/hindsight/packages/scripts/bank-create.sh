#!/bin/sh
#shellcheck enable=all
set -eu

bank_id="${1:?Usage: hindsight-bank-create <bank_id> <config.json>}"
config_file="${2:?Usage: hindsight-bank-create <bank_id> <config.json>}"

test -f "${config_file}"
docker exec -i hindsight hindsight-api bank create \
  --bank-id "${bank_id}" \
  --config /dev/stdin < "${config_file}"
