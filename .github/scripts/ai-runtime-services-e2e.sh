#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)
cd "$root"

home='.#nixosConfigurations.Victus.config.home-manager.users.craole'
session=$(nix eval --json "$home.home.sessionVariables")
units=$(nix eval --json "$home.systemd.user")
linger=$(nix eval --json .#nixosConfigurations.Victus.config.users.users.craole.linger)
packages=$(nix eval --json "$home.home.packages" --apply 'xs: map (x: x.name) xs')

printf '%s' "$session" | jq -e '
  .OPENAI_BASE_URL == "http://127.0.0.1:8787/v1"
  and .OPENAI_TARGET_API_URL == "http://127.0.0.1:20129"
  and .HERMES_MODEL_PROVIDER == "openai-codex"
  and .HERMES_MODEL_DEFAULT == "gpt-5.6-terra"
  and .HERMES_DELEGATION_PROVIDER == "openai-codex"
  and .HERMES_DELEGATION_MODEL == "gpt-5.6-terra"
  and .HERMES_DELEGATION_REASONING_EFFORT == "medium"
  and .HERMES_REVIEW_PROVIDER == "openai-codex"
  and .HERMES_REVIEW_MODEL == "gpt-5.6-sol"
  and .HERMES_MODEL_ALIAS_LUNA == "gpt-5.6-luna"
  and .HERMES_MODEL_ALIAS_TERRA == "gpt-5.6-terra"
  and .HERMES_MODEL_ALIAS_SOL == "gpt-5.6-sol"
  and .HERMES_MODEL_ALIAS_ASTRA == "gpt-6-astra"
  and .HERMES_MODEL_ALIAS_NINE == "openrouter/openrouter/free"
  and .HERMES_9ROUTER_PROVIDER == "custom:9router"
  and .HERMES_9ROUTER_BASE_URL == .OPENAI_BASE_URL
  and .API_SERVER_PORT == "8643"
  and (.HERMES_HOME | test("/\\.local/share/ai/hermes-victus$"))
  and .HINDSIGHT_BANK_ID == "hermes-victus"
  and .HINDSIGHT_RECALL_BUDGET == "mid"
' > /dev/null
test "$linger" = true
printf '%s' "$packages" | jq -e 'any(.[]; startswith("hermes-agent-"))' > /dev/null
printf '%s' "$packages" | jq -e 'any(.[]; startswith("hermes-desktop-ai-runtime"))' > /dev/null

target=$(printf '%s' "$units" | jq -c '.targets."ai-runtime"')
printf '%s' "$target" | jq -e '
  .Install.WantedBy == ["default.target"]
  and (.Unit.Wants | sort) == [
    "ai-9router.service",
    "ai-headroom.service",
    "ai-hermes-gateway.service",
    "ai-hindsight-ui.service",
    "ai-hindsight.service"
  ]
' > /dev/null

service() {
  printf '%s' "$units" | jq -c ".services.\"$1\""
}

router=$(service ai-9router)
headroom=$(service ai-headroom)
hindsight=$(service ai-hindsight)
hindsight_ui=$(service ai-hindsight-ui)
gateway=$(service ai-hermes-gateway)

for unit in "$router" "$headroom" "$hindsight" "$hindsight_ui" "$gateway"; do
  printf '%s' "$unit" | jq -e '
    .Service.Restart == "on-failure"
    and .Service.RestartSec == 5
    and ([.Service.ExecStart[]] | all(test("tmux") | not))
  ' > /dev/null
done

printf '%s' "$router" | jq -e '
  (.Service.ExecStart[0] | endswith("/bin/9router-start"))
  and (.Unit.After | index("network-online.target"))
' > /dev/null
grep -F 'exec 9router --host "$HOSTNAME" --port "$PORT" --no-browser --skip-update' \
  Modules/nix/global/ai/router/nine-router/default.nix > /dev/null
grep -F 'runtimeInputs = [nodejs_22 cacert tailscale];' \
  Modules/nix/global/ai/router/nine-router/default.nix > /dev/null

printf '%s' "$headroom" | jq -e '
  (.Service.ExecStart[0] | endswith("/bin/headroom-start"))
  and .Unit.Requires == ["ai-9router.service"]
  and .Unit.After == ["ai-9router.service"]
  and (.Service.Environment | index("HEADROOM_SAVINGS_PROFILE=coding"))
  and (.Service.Environment | index("HEADROOM_MODE=token"))
  and (.Service.Environment | index("HEADROOM_CODE_AWARE_ENABLED=1"))
  and (.Service.Environment | index("HEADROOM_LOSSLESS=1"))
  and (.Service.Environment | index("HEADROOM_TELEMETRY=on"))
  and (.Service.Environment | index("HEADROOM_PROVIDER_NAME=9Router"))
  and (.Service.Environment | index("OPENAI_TARGET_API_URL=http://127.0.0.1:20129"))
' > /dev/null
grep -F 'headroom-ai[proxy,code]==${version}' Modules/nix/global/ai/context/headroom/default.nix > /dev/null
grep -F -- '--mode "$HEADROOM_MODE"' Modules/nix/global/ai/context/headroom/default.nix > /dev/null
grep -F -- '--code-aware' Modules/nix/global/ai/context/headroom/default.nix > /dev/null
grep -F -- '--lossless' Modules/nix/global/ai/context/headroom/default.nix > /dev/null

printf '%s' "$hindsight" | jq -e '
  (.Service.ExecStart[0] | endswith("/bin/hindsight-service-start"))
  and ([.Service.Environment[] | select(test("^HINDSIGHT_DATA_DIR=.*/\\.local/share/ai/hindsight/default$"))] | length == 1)
  and ([.Service.Environment[] | select(test("^HINDSIGHT_SECRETS_FILE=.*/Private/hindsight\\.env$"))] | length == 1)
  and ([.Service.Environment[] | select(test("API_KEY|OPENROUTER_API_KEY|NINE_ROUTER_API_KEY"))] | length == 0)
' > /dev/null

printf '%s' "$hindsight_ui" | jq -e '
  (.Service.ExecStart[0] | endswith("/bin/hindsight-ui-start"))
  and .Unit.Requires == ["ai-hindsight.service"]
  and .Unit.After == ["ai-hindsight.service"]
' > /dev/null

printf '%s' "$gateway" | jq -e '
  (.Service.ExecCondition | endswith("/bin/hermes-gateway-ready"))
  and (.Service.ExecStart[0] | endswith("/bin/hermes-gateway-ai-runtime"))
  and (.Unit.Requires | sort) == [
    "ai-headroom.service",
    "ai-hindsight.service"
  ]
  and (.Unit.After | sort) == [
    "ai-headroom.service",
    "ai-hindsight.service"
  ]
  and ([.Service.Environment[] | select(test("TELEGRAM_BOT_TOKEN|TELEGRAM_ALLOWED_USERS"))] | length == 0)
' > /dev/null
grep -F 'name = "hermes-gateway-ready";' Modules/nix/home/ai/runtime.nix > /dev/null
grep -F 'name = "hermes-gateway-ai-runtime";' Modules/nix/home/ai/runtime.nix > /dev/null
grep -F 'name = "hermes-with-private-secrets";' Modules/nix/home/ai/runtime.nix > /dev/null
grep -F 'NINE_ROUTER_API_KEY' Modules/nix/home/ai/runtime.nix > /dev/null
grep -F 'providers.9router.key_env OPENAI_API_KEY' Modules/nix/home/ai/runtime.nix > /dev/null
grep -F 'name = "hermes-desktop-ai-runtime";' Modules/nix/home/ai/runtime.nix > /dev/null
grep -F 'HERMES_DESKTOP_USER_DATA_DIR="$HERMES_HOME/desktop-user-data"' Modules/nix/home/ai/runtime.nix > /dev/null
grep -F 'hermesHome = "${dataRoot}/hermes-${toLower host.name}";' Modules/nix/home/ai/runtime.nix > /dev/null
grep -F 'activation.linkManagedHermesHome' Modules/nix/home/ai/runtime.nix > /dev/null

printf '%s\n' 'PASS: persistent AI runtime target, services, gateway, desktop launcher, and environment contracts'
