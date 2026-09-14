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
  and .HINDSIGHT_BANK_ID == "hermes-victus"
  and .HINDSIGHT_RECALL_BUDGET == "mid"
' >/dev/null
test "$linger" = true
printf '%s' "$packages" | jq -e 'any(.[]; startswith("hermes-agent-"))' >/dev/null

target=$(printf '%s' "$units" | jq -c '.targets."ai-runtime"')
printf '%s' "$target" | jq -e '
  .Install.WantedBy == ["default.target"]
  and (.Unit.Wants | sort) == [
    "ai-9router.service",
    "ai-headroom.service",
    "ai-hindsight-ui.service",
    "ai-hindsight.service"
  ]
' >/dev/null

service() {
  printf '%s' "$units" | jq -c ".services.\"$1\""
}

router=$(service ai-9router)
headroom=$(service ai-headroom)
hindsight=$(service ai-hindsight)
hindsight_ui=$(service ai-hindsight-ui)

for unit in "$router" "$headroom" "$hindsight" "$hindsight_ui"; do
  printf '%s' "$unit" | jq -e '
    .Service.Restart == "on-failure"
    and .Service.RestartSec == 5
    and ([.Service.ExecStart[]] | all(test("tmux") | not))
  ' >/dev/null
done

printf '%s' "$router" | jq -e '
  (.Service.ExecStart[0] | endswith("/bin/9router-start"))
  and (.Unit.After | index("network-online.target"))
' >/dev/null
grep -F 'exec 9router --host "$HOSTNAME" --port "$PORT" --no-browser --skip-update' \
  Modules/nix/global/ai/router/nine-router/default.nix >/dev/null

printf '%s' "$headroom" | jq -e '
  (.Service.ExecStart[0] | endswith("/bin/headroom-start"))
  and .Unit.Requires == ["ai-9router.service"]
  and .Unit.After == ["ai-9router.service"]
  and (.Service.Environment | index("HEADROOM_SAVINGS_PROFILE=coding"))
  and (.Service.Environment | index("HEADROOM_MODE=token"))
  and (.Service.Environment | index("HEADROOM_CODE_AWARE_ENABLED=1"))
  and (.Service.Environment | index("HEADROOM_TELEMETRY=on"))
  and (.Service.Environment | index("HEADROOM_PROVIDER_NAME=9Router"))
  and (.Service.Environment | index("OPENAI_TARGET_API_URL=http://127.0.0.1:20129"))
' >/dev/null
grep -F 'headroom-ai[proxy,code]==${version}' Modules/nix/global/ai/context/headroom/default.nix >/dev/null
grep -F -- '--mode "$HEADROOM_MODE"' Modules/nix/global/ai/context/headroom/default.nix >/dev/null
grep -F -- '--code-aware' Modules/nix/global/ai/context/headroom/default.nix >/dev/null

printf '%s' "$hindsight" | jq -e '
  (.Service.ExecStart[0] | endswith("/bin/hindsight-service-start"))
  and ([.Service.Environment[] | select(test("^HINDSIGHT_DATA_DIR=.*/\\.local/share/ai/hindsight/default$"))] | length == 1)
  and ([.Service.Environment[] | select(test("^HINDSIGHT_SECRETS_FILE=.*/Private/hindsight\\.env$"))] | length == 1)
  and ([.Service.Environment[] | select(test("API_KEY|OPENROUTER_API_KEY|NINE_ROUTER_API_KEY"))] | length == 0)
' >/dev/null

printf '%s' "$hindsight_ui" | jq -e '
  (.Service.ExecStart[0] | endswith("/bin/hindsight-ui-start"))
  and .Unit.Requires == ["ai-hindsight.service"]
  and .Unit.After == ["ai-hindsight.service"]
' >/dev/null

printf '%s\n' 'PASS: persistent AI runtime target, services, and environment contracts'
