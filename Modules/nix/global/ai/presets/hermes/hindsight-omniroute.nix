{
  agents,
  memory,
  router,
  cfg,
  lix,
  paths,
  ...
} @ args: let
  integration = import ./hindsight-integration.nix args;
  h = cfg.hindsight;
  o = cfg.omniroute;
in
  import ./lib.nix {
    inherit cfg lix paths;
    name = "hermes-hindsight-omniroute";
    components = [
      router.omniroute
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

      export OMNIROUTE_PORT="$(( ${toString o.port} + AI_PORT_OFFSET ))"
      export OMNIROUTE_BASE_URL="http://${o.bindAddress}:$OMNIROUTE_PORT/v1"
      export OMNIROUTE_DATA_DIR="$AI_HOME/${o.state}"
      export OMNIROUTE_NPX_CACHE="$AI_CACHE_DIR/${o.state}/npx"
      export OMNIROUTE_SESSION="$AI_PRESET-$AI_INSTANCE-${o.session}"
      export OPENAI_BASE_URL="$OMNIROUTE_BASE_URL"
      if [ -n "''${OMNIROUTE_API_KEY:-}" ]; then
        export OPENAI_API_KEY="$OMNIROUTE_API_KEY"
      fi
    '';

    start = ''
      if ! omniroute-status > /dev/null 2>&1; then
        omniroute-daemon || true
      fi

      configure-hindsight --force || true

      if [ -r "$HINDSIGHT_SECRETS_FILE" ]; then
        if ! hindsight-status > /dev/null 2>&1; then
          hindsight-up || true
        fi
      else
        printf '%s\n' "Hindsight not started: missing $HINDSIGHT_SECRETS_FILE"
      fi

      if [ -z "''${OMNIROUTE_MODEL:-}" ]; then
        printf '%s\n' "OmniRoute is available at $OMNIROUTE_BASE_URL; set OMNIROUTE_MODEL to select the Hermes routed model."
      fi
    '';
  }
