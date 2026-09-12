#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)
cd "$root"

test_home=$(mktemp -d)
cleanup() {
  HOME="$test_home" nix develop .#Victus-ai-9router --command 9router-stop >/dev/null 2>&1 || true
  HOME="$test_home" nix develop .#Victus-ai-headroom --command headroom-stop >/dev/null 2>&1 || true
  rm -rf "$test_home"
}
trap cleanup EXIT HUP INT TERM

HOME="$test_home" nix develop .#Victus-ai-9router --command sh -lc '
  set -eu
  test "$NINE_ROUTER_PORT" = 20129
  test "$NINE_ROUTER_BIND_ADDRESS" = 127.0.0.1
  test "$NINE_ROUTER_BASE_URL" = http://127.0.0.1:20129/v1
  test "$NINE_ROUTER_DATA_DIR" = "$HOME/.local/share/ai/9router"
  command -v 9router >/dev/null
  command -v 9router-daemon >/dev/null
  command -v 9router-status >/dev/null
  9router --help >/dev/null
'

HOME="$test_home" nix develop .#Victus-ai-headroom --command sh -lc '
  set -eu
  test "$HEADROOM_PORT" = 8787
  test "$HEADROOM_HOST" = 127.0.0.1
  test "$HEADROOM_BASE_URL" = http://127.0.0.1:8787
  test "$HEADROOM_WORKSPACE_DIR" = "$HOME/.local/share/ai/headroom"
  test "$HEADROOM_CONFIG_DIR" = "$HOME/.config/ai/headroom"
  command -v headroom >/dev/null
  command -v headroom-daemon >/dev/null
  command -v headroom-status >/dev/null
  headroom --version >/dev/null
'

HOME="$test_home" nix develop .#Victus-ai-hermes-hindsight-9router --command sh -lc '
  set -eu
  test "$AI_PRESET" = hermes-hindsight-9router
  test "$NINE_ROUTER_DATA_DIR" = "$AI_HOME/9router"
  test "$NINE_ROUTER_SESSION" = hermes-hindsight-9router-default-9router
  test "$OPENAI_BASE_URL" = "$NINE_ROUTER_BASE_URL"
  command -v hermes >/dev/null
  command -v 9router >/dev/null
  command -v configure-hindsight >/dev/null
  if env | grep -q "^HEADROOM_"; then
    printf "%s\n" "Headroom leaked into the 9Router-only preset" >&2
    exit 1
  fi
'

HOME="$test_home" nix develop .#Victus-ai-hermes-hindsight-headroom-9router --command sh -lc '
  set -eu
  test "$AI_PRESET" = hermes-hindsight-headroom-9router
  test "$NINE_ROUTER_DATA_DIR" = "$AI_HOME/9router"
  test "$HEADROOM_WORKSPACE_DIR" = "$AI_HOME/headroom"
  test "$HEADROOM_CONFIG_DIR" = "$AI_HOME/headroom/config"
  test "$OPENAI_TARGET_API_URL" = "$NINE_ROUTER_BASE_URL"
  test "$OPENAI_BASE_URL" = "$HEADROOM_BASE_URL/v1"
  command -v hermes >/dev/null
  command -v headroom >/dev/null
  command -v 9router >/dev/null
  command -v configure-hindsight >/dev/null
'

printf '%s\n' 'PASS: 9Router + Headroom contracts'
