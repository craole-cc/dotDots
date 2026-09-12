{
  agents,
  context,
  memory,
  router,
  cfg,
  paths,
  ...
} @ args: let
  integration = import ./hindsight-integration.nix args;
  h = cfg.hindsight;
  c = cfg.headroom;
  r = cfg.nineRouter;
in
  import ./lib.nix {
    inherit cfg paths;
    name = "hermes-hindsight-headroom-nine-router";
    components = [
      router."nine-router"
      context.headroom
      memory.hindsight
      integration
      agents.hermes
    ];

    init = ''
      export HINDSIGHT_INSTANCE="''${HINDSIGHT_INSTANCE:-$AI_INSTANCE}"
      export HINDSIGHT_SECRETS_FILE="''${HINDSIGHT_SECRETS_FILE:-$AI_PRIVATE_DIR/${h.secrets}}"
      export HINDSIGHT_BIND_ADDRESS="''${HINDSIGHT_BIND_ADDRESS:-$AI_BIND_ADDRESS}"
      export HINDSIGHT_API_PORT="$(( ${toString h.ports.api} + AI_PORT_OFFSET ))"
      export HINDSIGHT_MCP_PORT="$(( ${toString h.ports.mcp} + AI_PORT_OFFSET ))"
      export HINDSIGHT_UI_PORT="$(( ${toString h.ports.ui} + AI_PORT_OFFSET ))"
      export HINDSIGHT_API_URL="http://$HINDSIGHT_BIND_ADDRESS:$HINDSIGHT_API_PORT"
      export HINDSIGHT_IMAGE="''${HINDSIGHT_IMAGE:-${h.image}}"
      export HINDSIGHT_LLM_BACKEND="''${HINDSIGHT_LLM_BACKEND:-${h.llm.backend}}"
      export HINDSIGHT_LLM_BASE_URL="''${HINDSIGHT_LLM_BASE_URL:-${h.llm.baseUrl}}"
      export HINDSIGHT_LLM_MODEL="''${HINDSIGHT_LLM_MODEL:-${h.llm.model}}"
      export HINDSIGHT_REFLECT_LLM_MODEL="''${HINDSIGHT_REFLECT_LLM_MODEL:-${h.llm.reflectModel}}"
      export HINDSIGHT_MODE="''${HINDSIGHT_MODE:-${h.mode}}"
      export HINDSIGHT_BANK_ID="''${HINDSIGHT_BANK_ID:-${h.bank}}"
      export HINDSIGHT_RECALL_BUDGET="''${HINDSIGHT_RECALL_BUDGET:-${h.recallBudget}}"
      export HINDSIGHT_COMPOSE_PROJECT="hindsight-$HINDSIGHT_INSTANCE"
      export HINDSIGHT_CONTAINER_NAME="hindsight-$HINDSIGHT_INSTANCE"

      export NINE_ROUTER_PORT="$(( ${toString r.port} + AI_PORT_OFFSET ))"
      export NINE_ROUTER_BIND_ADDRESS="''${NINE_ROUTER_BIND_ADDRESS:-${r.bindAddress}}"
      export NINE_ROUTER_BASE_URL="http://$NINE_ROUTER_BIND_ADDRESS:$NINE_ROUTER_PORT/v1"
      export NINE_ROUTER_DATA_DIR="$AI_HOME/${r.state}"
      export NINE_ROUTER_NPM_CACHE="$AI_CACHE_DIR/${r.state}/npm"
      export NINE_ROUTER_SESSION="$AI_PRESET-$AI_INSTANCE-${r.session}"

      export HEADROOM_HOST="''${HEADROOM_HOST:-${c.bindAddress}}"
      export HEADROOM_PORT="$(( ${toString c.port} + AI_PORT_OFFSET ))"
      export HEADROOM_BASE_URL="http://$HEADROOM_HOST:$HEADROOM_PORT"
      export HEADROOM_WORKSPACE_DIR="$AI_HOME/${c.state}"
      export HEADROOM_CONFIG_DIR="$AI_HOME/${c.state}/config"
      export HEADROOM_UV_CACHE="$AI_CACHE_DIR/${c.state}/uv"
      export HEADROOM_SESSION="$AI_PRESET-$AI_INSTANCE-${c.session}"
      export OPENAI_TARGET_API_URL="$NINE_ROUTER_BASE_URL"
      export OPENAI_BASE_URL="$HEADROOM_BASE_URL/v1"
      if [ -n "''${NINE_ROUTER_API_KEY:-}" ]; then
        export OPENAI_API_KEY="$NINE_ROUTER_API_KEY"
      fi
    '';

    start = ''
      if ! nine-router-status > /dev/null 2>&1; then
        nine-router-daemon || true
      fi

      if ! headroom-status > /dev/null 2>&1; then
        headroom-daemon || true
      fi

      configure-hindsight --force || true

      if [ -r "$HINDSIGHT_SECRETS_FILE" ]; then
        if ! hindsight-status > /dev/null 2>&1; then
          hindsight-up || true
        fi
      else
        printf '%s\n' "Hindsight not started: missing $HINDSIGHT_SECRETS_FILE"
      fi
    '';
  }
