{
  agents,
  memory,
  router,
  ...
} @ args: let
  integration = import ./hindsight-integration.nix args;
in
  import ./lib.nix {
    name = "hermes-hindsight-omniroute";
    components = [
      router.omniroute
      memory.hindsight
      integration
      agents.hermes
    ];

    init = ''
      export HINDSIGHT_INSTANCE="''${HINDSIGHT_INSTANCE:-$AI_INSTANCE}"
      export HINDSIGHT_SECRETS_FILE="''${HINDSIGHT_SECRETS_FILE:-''${PRIVATE:-$HOME/Private}/hindsight.env}"
      export HINDSIGHT_BIND_ADDRESS="$AI_BIND_ADDRESS"
      export HINDSIGHT_API_PORT="$((8888 + AI_PORT_OFFSET))"
      export HINDSIGHT_MCP_PORT="$((9999 + AI_PORT_OFFSET))"
      export HINDSIGHT_UI_PORT="$((8889 + AI_PORT_OFFSET))"
      export HINDSIGHT_API_URL="http://$HINDSIGHT_BIND_ADDRESS:$HINDSIGHT_API_PORT"
      export HINDSIGHT_MODE="''${HINDSIGHT_MODE:-local_external}"
      export HINDSIGHT_BANK_ID="''${HINDSIGHT_BANK_ID:-hermes}"
      export HINDSIGHT_RECALL_BUDGET="''${HINDSIGHT_RECALL_BUDGET:-mid}"
      export HINDSIGHT_COMPOSE_PROJECT="hindsight-$HINDSIGHT_INSTANCE"
      export HINDSIGHT_CONTAINER_NAME="hindsight-$HINDSIGHT_INSTANCE"

      export OMNIROUTE_PORT="$((20128 + AI_PORT_OFFSET))"
      export OMNIROUTE_BASE_URL="http://127.0.0.1:$OMNIROUTE_PORT/v1"
      export OMNIROUTE_DATA_DIR="$AI_HOME/omniroute"
      export OMNIROUTE_NPX_CACHE="''${XDG_CACHE_HOME:-$HOME/.cache}/ai/$AI_PRESET/$AI_INSTANCE/omniroute/npx"
      export OMNIROUTE_SESSION="$AI_PRESET-$AI_INSTANCE-omniroute"
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
