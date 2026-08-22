#!/bin/sh
set -eu

no_confirm=0
for arg in "$@"; do
  case "$arg" in
  --no-confirm | -y) no_confirm=1 ;;
  esac
done

if [ -n "${HERMES_ENV_SH:-}" ] && [ -f "$HERMES_ENV_SH" ]; then
  # shellcheck disable=SC1090
  . "$HERMES_ENV_SH"
fi

mkdir -p "${HERMES_HOME:?HERMES_HOME not set}"

if ! command -v hermes >/dev/null 2>&1; then
  echo "hermes not on PATH" >&2
  exit 1
fi

if [ "$no_confirm" -eq 1 ]; then
  echo "Starting hermes gateway..."
  hermes gateway start 2>/dev/null || hermes serve 2>/dev/null || true
else
  echo "Hermes CLI available. Try: hermes --help | hermes gateway start"
fi
