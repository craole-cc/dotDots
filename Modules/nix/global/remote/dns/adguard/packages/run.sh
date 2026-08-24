#!/bin/sh
#shellcheck enable=all
set -eu

: "${ADGUARD_DATA_DIR:?ADGUARD_DATA_DIR not set}"
: "${ADGUARD_CONFIG_FILE:?ADGUARD_CONFIG_FILE not set}"
: "${ADGUARD_PROCESS_FILE:?ADGUARD_PROCESS_FILE not set}"

mkdir -p "${ADGUARD_DATA_DIR}"
exec process-compose -f "${ADGUARD_PROCESS_FILE}" up
