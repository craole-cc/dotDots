#!/bin/sh
#shellcheck enable=all
set -eu

repo_root="$(CDPATH='' cd -- "$(dirname -- "$0")/../../../../../../../.." && pwd)"
env_sh="$repo_root/Modules/nix/global/ai/agents/hermes/environment/env.sh"
runtime="$repo_root/Modules/nix/global/ai/agents/hermes/middleware/telegram/runtime.sh"
fixture="$(mktemp -d)"
trap 'rm -rf "$fixture"' EXIT

mkdir -m 700 "$fixture/home"
printf '%s\n' \
  'TELEGRAM_BOT_TOKEN=redacted-token' \
  'TELEGRAM_ALLOWED_USERS=123456' \
  'TELEGRAM_HOME_CHANNEL=-100987654' \
  'TELEGRAM_HOME_CHANNEL_NAME=Home' \
  >"$fixture/home/.env"
chmod 600 "$fixture/home/.env"

HERMES_HOME="$fixture/home"
HERMES_ENV_SH="$env_sh"
HERMES_ENV_PY=/bin/false
export HERMES_HOME HERMES_ENV_SH HERMES_ENV_PY
. "$runtime"

[ "$HERMES_TELEGRAM_BOT_TOKEN" = 'redacted-token' ]
[ "$HERMES_TELEGRAM_ALLOWED_USERS" = '123456' ]
[ "$HERMES_TELEGRAM_HOME_CHANNEL" = '-100987654' ]
[ "$HERMES_TELEGRAM_HOME_CHANNEL_NAME" = 'Home' ]
printf '%s\n' 'telegram runtime environment fixture: PASS (values redacted)'
