#!/bin/sh
set -eu

preset=${1:?usage: ai-preset-e2e.sh PRESET}
host=${AI_E2E_HOST:-Victus}
shell=".#${host}-ai-${preset}"
root=$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)
cd "$root"

test_home=$(mktemp -d)
fixture_pid=""

cleanup() {
  if [ -n "$fixture_pid" ]; then
    kill "$fixture_pid" 2>/dev/null || true
    wait "$fixture_pid" 2>/dev/null || true
  fi
  rm -rf "$test_home"
}
trap cleanup EXIT HUP INT TERM

inner="$test_home/e2e.sh"

case "$preset" in
  hermes)
    cat >"$inner" <<'EOF'
#!/bin/sh
set -eu

test "$AI_PRESET" = hermes
test "$AI_INSTANCE" = default
test "$AI_HOME" = "$HOME/.local/share/ai/hermes/default"
test "$HERMES_HOME" = "$AI_HOME/hermes"
test "$HERMES_GATEWAY_CFG" = "$HERMES_HOME/gateway.json"

command -v hermes >/dev/null
command -v hermes-help >/dev/null
command -v hermes-gateway-service >/dev/null
command -v hermes-whatsapp >/dev/null
test -f "$HERMES_WHATSAPP_GATEWAY_PY"
hermes --help >/dev/null
hermes-help >/dev/null

if command -v configure-hindsight >/dev/null 2>&1; then
  printf '%s\n' 'Hindsight integration leaked into ai-hermes' >&2
  exit 1
fi

for prefix in HINDSIGHT_ OMNIROUTE_ MEM0_; do
  if env | grep -q "^$prefix"; then
    printf '%s leaked into ai-hermes\n' "$prefix" >&2
    exit 1
  fi
done

unit=$(hermes-gateway-service)
printf '%s\n' "$unit" | grep -F "WorkingDirectory=$HERMES_HOME" >/dev/null
printf '%s\n' "$unit" | grep -F "Environment=HERMES_HOME=$HERMES_HOME" >/dev/null
printf '%s\n' "$unit" | grep -F "Environment=HERMES_GATEWAY_CFG=$HERMES_GATEWAY_CFG" >/dev/null
EOF
    HOME="$test_home" nix develop "$shell" --command sh "$inner"
    ;;

  hermes-hindsight)
    cat >"$inner" <<'EOF'
#!/bin/sh
set -eu

stop() {
  hindsight-down >/dev/null 2>&1 || true
}
trap stop EXIT HUP INT TERM

test "$AI_PRESET" = hermes-hindsight
test "$AI_HOME" = "$HOME/.local/share/ai/hermes-hindsight/default"
test "$HERMES_HOME" = "$AI_HOME/hermes"
test "$HINDSIGHT_INSTANCE" = default
test "$HINDSIGHT_SECRETS_FILE" = "$HOME/Private/hindsight.env"
test "$HINDSIGHT_LLM_BACKEND" = openrouter
test "$HINDSIGHT_IMAGE" = ghcr.io/vectorize-io/hindsight:0.9.2
test "$HINDSIGHT_BIND_ADDRESS" = 127.0.0.1
test "$HINDSIGHT_API_PORT" = 8888
test "$HINDSIGHT_MCP_PORT" = 9999
test "$HINDSIGHT_UI_PORT" = 8889
test "$HINDSIGHT_API_URL" = http://127.0.0.1:8888
test "$HINDSIGHT_COMPOSE_PROJECT" = hindsight-default
test "$HINDSIGHT_CONTAINER_NAME" = hindsight-default

for command in hermes configure-hindsight hindsight-help hindsight-up hindsight-down hindsight-status hindsight-verify hindsight-storage; do
  command -v "$command" >/dev/null
done

if env | grep -q '^OMNIROUTE_'; then
  printf '%s\n' 'OmniRoute leaked into ai-hermes-hindsight' >&2
  exit 1
fi
if env | grep -q '^MEM0_'; then
  printf '%s\n' 'Mem0 leaked into ai-hermes-hindsight' >&2
  exit 1
fi

configure-hindsight --force
test -s "$HERMES_HOME/hindsight/config.json"
grep -F "\"api_url\": \"$HINDSIGHT_API_URL\"" "$HERMES_HOME/hindsight/config.json" >/dev/null
grep -F "\"bank_id\": \"$HINDSIGHT_BANK_ID\"" "$HERMES_HOME/hindsight/config.json" >/dev/null

mkdir -p "$(dirname "$HINDSIGHT_SECRETS_FILE")"
printf '%s\n' 'HINDSIGHT_OPENROUTER_API_KEY=ci-dummy-key' >"$HINDSIGHT_SECRETS_FILE"

hindsight-up
hindsight-status
hindsight-verify
hindsight-storage
hindsight-down
trap - EXIT HUP INT TERM
EOF
    HOME="$test_home" nix develop "$shell" --command sh "$inner"
    ;;

  hermes-mem0)
    python3 .github/scripts/mem0-fixture.py 8888 >"$test_home/mem0-fixture.log" 2>&1 &
    fixture_pid=$!

    attempts=0
    until curl -fsS http://127.0.0.1:8888/openapi.json >/dev/null 2>&1; do
      attempts=$((attempts + 1))
      if [ "$attempts" -ge 30 ]; then
        cat "$test_home/mem0-fixture.log" >&2
        exit 1
      fi
      sleep 1
    done

    cat >"$inner" <<'EOF'
#!/bin/sh
set -eu

test "$AI_PRESET" = hermes-mem0
test "$AI_HOME" = "$HOME/.local/share/ai/hermes-mem0/default"
test "$HERMES_HOME" = "$AI_HOME/hermes"
test "$MEM0_PORT" = 8888
test "$MEM0_BASE_URL" = http://127.0.0.1:8888
test "$MEM0_HOST" = "$MEM0_BASE_URL"

for command in hermes mem0 mem0-status mem0-verify; do
  command -v "$command" >/dev/null
done

if command -v configure-hindsight >/dev/null 2>&1 || env | grep -q '^HINDSIGHT_' || env | grep -q '^OMNIROUTE_'; then
  printf '%s\n' 'Unrequested integration leaked into ai-hermes-mem0' >&2
  exit 1
fi

mem0-status
mem0-verify
hermes config set memory.provider mem0
hermes config set security.allow_lazy_installs false

hermes_wrapper=$(command -v hermes)
hermes_root=$(dirname "$(dirname "$hermes_wrapper")")
hermes_python=$(sed -n "s|.*HERMES_PYTHON='\([^']*\)'.*|\1|p" "$hermes_wrapper" | sed -n '1p')
test -n "$hermes_python"
test -x "$hermes_python"

PYTHONPATH="$hermes_root/share/hermes-agent${PYTHONPATH:+:$PYTHONPATH}" "$hermes_python" <<'PY'
import json
from plugins.memory.mem0 import Mem0MemoryProvider

provider = Mem0MemoryProvider()
assert provider.is_available(), "Mem0 provider did not detect MEM0_HOST"
provider.initialize("ci-session", user_id="ci-user", platform="ci")

added = json.loads(provider.handle_tool_call("mem0_add", {"content": "CI memory"}))
assert added.get("result") == "Fact stored.", added

found = json.loads(provider.handle_tool_call("mem0_search", {"query": "CI memory"}))
assert found.get("count") == 1, found
assert found["results"][0]["id"] == "ci-memory", found
assert found["results"][0]["memory"] == "CI memory", found

updated = json.loads(provider.handle_tool_call("mem0_update", {"memory_id": "ci-memory", "text": "Updated CI memory"}))
assert updated.get("result") == "Memory updated.", updated
found = json.loads(provider.handle_tool_call("mem0_search", {"query": "Updated"}))
assert found["results"][0]["memory"] == "Updated CI memory", found

deleted = json.loads(provider.handle_tool_call("mem0_delete", {"memory_id": "ci-memory"}))
assert deleted.get("result") == "Memory deleted.", deleted
empty = json.loads(provider.handle_tool_call("mem0_search", {"query": "CI memory"}))
assert empty.get("result") == "No relevant memories found.", empty

provider.shutdown()
PY
EOF
    HOME="$test_home" nix develop "$shell" --command sh "$inner"
    ;;

  hermes-hindsight-omniroute)
    cat >"$inner" <<'EOF'
#!/bin/sh
set -eu

stop() {
  hindsight-down >/dev/null 2>&1 || true
  omniroute-stop >/dev/null 2>&1 || true
}
trap stop EXIT HUP INT TERM

test "$AI_PRESET" = hermes-hindsight-omniroute
test "$AI_HOME" = "$HOME/.local/share/ai/hermes-hindsight-omniroute/default"
test "$HERMES_HOME" = "$AI_HOME/hermes"
test "$HINDSIGHT_INSTANCE" = default
test "$HINDSIGHT_SECRETS_FILE" = "$HOME/Private/hindsight.env"
test "$HINDSIGHT_LLM_BACKEND" = openrouter
test "$HINDSIGHT_COMPOSE_PROJECT" = hindsight-default
test "$HINDSIGHT_CONTAINER_NAME" = hindsight-default
test "$HINDSIGHT_IMAGE" = ghcr.io/vectorize-io/hindsight:0.9.2
test "$OMNIROUTE_DATA_DIR" = "$AI_HOME/omniroute"
test "$OMNIROUTE_PORT" = 20128
test "$OMNIROUTE_SESSION" = hermes-hindsight-omniroute-default-omniroute
test "$OPENAI_BASE_URL" = "$OMNIROUTE_BASE_URL"

for command in curl hermes configure-hindsight hindsight-up hindsight-down hindsight-status hindsight-verify omniroute omniroute-daemon omniroute-status omniroute-stop; do
  command -v "$command" >/dev/null
done

if env | grep -q '^MEM0_'; then
  printf '%s\n' 'Mem0 leaked into ai-hermes-hindsight-omniroute' >&2
  exit 1
fi

omniroute --version >/dev/null
omniroute-daemon

attempts=0
until curl -fsS "$OMNIROUTE_BASE_URL/models" >"$AI_CACHE_DIR/omniroute-models.json" 2>/dev/null; do
  attempts=$((attempts + 1))
  if [ "$attempts" -ge 90 ]; then
    printf '%s\n' 'OmniRoute OpenAI endpoint did not become ready' >&2
    tmux capture-pane -pt "$OMNIROUTE_SESSION" 2>/dev/null || true
    exit 1
  fi
  sleep 2
done
omniroute-status

test -s "$AI_CACHE_DIR/omniroute-models.json"

configure-hindsight --force
mkdir -p "$(dirname "$HINDSIGHT_SECRETS_FILE")"
printf '%s\n' 'HINDSIGHT_OPENROUTER_API_KEY=ci-dummy-key' >"$HINDSIGHT_SECRETS_FILE"
hindsight-up
hindsight-status
hindsight-verify

hindsight-down
omniroute-stop
trap - EXIT HUP INT TERM
EOF
    HOME="$test_home" nix develop "$shell" --command sh "$inner"
    ;;

  *)
    printf 'Unknown AI preset: %s\n' "$preset" >&2
    exit 2
    ;;
esac

printf 'PASS: ai-%s\n' "$preset"
