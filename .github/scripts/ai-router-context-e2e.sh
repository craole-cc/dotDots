#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)
cd "$root"

test_home=$(mktemp -d)
mkdir -p "$test_home/Private"
printf '%s\n' 'OPENROUTER_API_KEY=test-hermes-openrouter-key' > "$test_home/Private/hermes.env"
chmod 600 "$test_home/Private/hermes.env"

provider_pid=""
router_pid=""
cleanup() {
  HOME="$test_home" nix develop .#Victus-ai-hermes-hindsight-headroom-9router --command headroom-stop >/dev/null 2>&1 || true
  HOME="$test_home" nix develop .#Victus-ai-9router --command 9router-stop >/dev/null 2>&1 || true
  HOME="$test_home" nix develop .#Victus-ai-hindsight --command hindsight-down >/dev/null 2>&1 || true
  [ -z "$router_pid" ] || kill "$router_pid" >/dev/null 2>&1 || true
  [ -z "$provider_pid" ] || kill "$provider_pid" >/dev/null 2>&1 || true
  rm -rf "$test_home"
}
trap cleanup EXIT HUP INT TERM

# Shell environment variables are available after entering the devShell, not
# as flake attributes. Host identity owns the memory namespace; the budget
# remains invariant.
HOME="$test_home" nix develop .#Victus-ai-hermes-hindsight-headroom-9router --command sh -lc '
  test "$HINDSIGHT_BANK_ID" = hermes-victus
  test "$HINDSIGHT_RECALL_BUDGET" = mid
'

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

HOME="$test_home" nix develop .#Victus-ai-hindsight --command sh -lc '
  set -eu
  test "$HINDSIGHT_API_URL" = http://127.0.0.1:8888
  test "$HINDSIGHT_UI_URL" = http://127.0.0.1:8889
  test "$HINDSIGHT_BANK_ID" = hermes-victus
  test "$HINDSIGHT_RECALL_BUDGET" = mid
  test "$HINDSIGHT_MODE" = local_external
  command -v hindsight-ui-start >/dev/null
  command -v hindsight-ui-daemon >/dev/null
  command -v hindsight-ui-status >/dev/null
  command -v hindsight-ui-stop >/dev/null
  if env | grep -q "^HINDSIGHT_API_KEY="; then
    printf "%s\n" "local_external unexpectedly requires HINDSIGHT_API_KEY" >&2
    exit 1
  fi
'

HOME="$test_home" nix develop .#Victus-ai-hermes-hindsight-9router --command sh -lc '
  set -eu
  test "$AI_PRESET" = hermes-hindsight-9router
  test "$NINE_ROUTER_DATA_DIR" = "$AI_HOME/9router"
  test "$NINE_ROUTER_SESSION" = hermes-hindsight-9router-default-9router
  test "$OPENAI_BASE_URL" = "$NINE_ROUTER_BASE_URL"
  test "$HINDSIGHT_BANK_ID" = hermes-victus
  test "$HERMES_SECRETS_FILE" = "$HOME/Private/hermes.env"
  test "$OPENROUTER_API_KEY" = test-hermes-openrouter-key
  test "$HERMES_DISABLE_LAZY_INSTALLS" = 1
  command -v hermes >/dev/null
  command -v 9router >/dev/null
  command -v configure-hindsight >/dev/null

  hermes_wrapper=$(command -v hermes)
  hermes_root=$(dirname "$(dirname "$hermes_wrapper")")
  hermes_python=$(sed -n "s|.*HERMES_PYTHON='\''\([^'\'']*\)'\''.*|\1|p" "$hermes_wrapper" | sed -n '"'"'1p'"'"')
  test -n "$hermes_python"
  test -x "$hermes_python"
  PYTHONPATH="$hermes_root/share/hermes-agent${PYTHONPATH:+:$PYTHONPATH}" \
    "$hermes_python" -c '"'"'import hindsight_client'"'"'

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
  test "$OPENAI_TARGET_API_URL" = "http://$NINE_ROUTER_BIND_ADDRESS:$NINE_ROUTER_PORT"
  test "$OPENAI_BASE_URL" = "$HEADROOM_BASE_URL/v1"
  test "$HERMES_MODEL_PROVIDER" = openai
  test "$HERMES_MODEL_BASE_URL" = "$OPENAI_BASE_URL"
  test "$HERMES_MODEL_DEFAULT" = cx/gpt-6-astra
  test "$HINDSIGHT_API_URL" = http://127.0.0.1:8888
  test "$HINDSIGHT_UI_URL" = http://127.0.0.1:8889
  test "$HINDSIGHT_BANK_ID" = hermes-victus
  test "$HINDSIGHT_RECALL_BUDGET" = mid
  test "$HERMES_SECRETS_FILE" = "$HOME/Private/hermes.env"
  test "$OPENROUTER_API_KEY" = test-hermes-openrouter-key
  test "$HERMES_DISABLE_LAZY_INSTALLS" = 1
  command -v hermes >/dev/null
  command -v headroom >/dev/null
  command -v 9router >/dev/null
  command -v configure-hindsight >/dev/null
  command -v hindsight-ui-status >/dev/null

  configure-hindsight --force
  test "$(hermes config get model.provider)" = openai
  test "$(hermes config get model.base_url)" = "$OPENAI_BASE_URL"
  test "$(hermes config get model.default)" = cx/gpt-6-astra
'

# Deterministic traversal: real Hermes -> real Headroom -> 9Router-shaped local
# endpoint -> local provider. The fixture records both downstream hops, while
# the 9Router package/readiness contract is covered independently above.
provider_marker="$test_home/provider.marker"
router_marker="$test_home/router.marker"
HOME="$test_home" nix develop .#Victus-ai-hermes-hindsight-headroom-9router --command \
  python3 .github/scripts/ai-stack-fixture.py provider --port 20130 --marker "$provider_marker" &
provider_pid=$!
HOME="$test_home" nix develop .#Victus-ai-hermes-hindsight-headroom-9router --command \
  python3 .github/scripts/ai-stack-fixture.py router --port 20129 --upstream http://127.0.0.1:20130 --marker "$router_marker" &
router_pid=$!

sleep 1

HOME="$test_home" OPENAI_API_KEY=test-local-key \
  nix develop .#Victus-ai-hermes-hindsight-headroom-9router --command sh -lc '
    set -eu
    9router-status >/dev/null
    headroom-daemon
    headroom-status >/dev/null
    answer=$(hermes -z "Reply exactly: traversal-ok" --provider openai-api --model test-model --ignore-rules)
    printf "%s\n" "$answer" | grep -F traversal-ok >/dev/null
  '

test "$(cat "$router_marker")" = /v1/chat/completions
test "$(cat "$provider_marker")" = /v1/chat/completions

printf '%s\n' 'PASS: Hindsight + Headroom + 9Router runtime contracts and traversal'
