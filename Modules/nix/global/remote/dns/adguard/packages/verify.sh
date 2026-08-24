#!/bin/sh
#shellcheck enable=all
set -eu

: "${ADGUARD_BIND_ADDRESS:?ADGUARD_BIND_ADDRESS not set}"
: "${ADGUARD_DNS_PORT:?ADGUARD_DNS_PORT not set}"
: "${ADGUARD_WEB_URL:?ADGUARD_WEB_URL not set}"

printf '%s\n' "DNS verification:"
dig +time=3 +tries=1 \
  "@${ADGUARD_BIND_ADDRESS}" \
  -p "${ADGUARD_DNS_PORT}" \
  google.com

printf '\n%s\n' "Web verification:"
curl --fail --silent --show-error --max-time 3 \
  --output /dev/null \
  --write-out 'HTTP %{http_code} %{url_effective}\n' \
  "${ADGUARD_WEB_URL}/"
