{
  agents,
  memory,
  ...
} @ args: let
  integration = import ./hindsight-integration.nix args;
in
  import ./lib.nix {
    name = "hermes-hindsight";
    components = [
      memory.hindsight
      integration
      agents.hermes
    ];

    init = ''
      export HINDSIGHT_INSTANCE="''${HINDSIGHT_INSTANCE:-$AI_INSTANCE}"
      export HINDSIGHT_SECRETS_FILE="''${HINDSIGHT_SECRETS_FILE:-''${PRIVATE:-$HOME/Private}/ai/hindsight/$HINDSIGHT_INSTANCE.env}"
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
    '';

    start = ''
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
