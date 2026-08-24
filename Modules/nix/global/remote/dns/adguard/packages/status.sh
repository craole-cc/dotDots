#!/bin/sh
#shellcheck enable=all
set -eu

: "${ADGUARD_BIND_ADDRESS:?ADGUARD_BIND_ADDRESS not set}"
: "${ADGUARD_DNS_PORT:?ADGUARD_DNS_PORT not set}"
: "${ADGUARD_WEB_URL:?ADGUARD_WEB_URL not set}"

dig +time=2 +tries=1 +short \
  "@${ADGUARD_BIND_ADDRESS}" \
  -p "${ADGUARD_DNS_PORT}" \
  google.com >/dev/null
curl --fail --silent --show-error --max-time 3 \
  "${ADGUARD_WEB_URL}/" >/dev/null
printf '%s\n' "AdGuard Home is responding at ${ADGUARD_WEB_URL} and ${ADGUARD_BIND_ADDRESS}:${ADGUARD_DNS_PORT}."
