{
  agents,
  memory,
  router,
  ...
}:
import ./lib.nix {
  name = "hermes-hindsight-omniroute";
  components = [
    router.omniroute
    memory.hindsight
    agents.hermes
  ];

  init = ''
    export HINDSIGHT_DATA_DIR="$AI_HOME/hindsight"
    export HINDSIGHT_SECRETS_FILE="''${HINDSIGHT_SECRETS_FILE:-''${PRIVATE:-$HOME/Private}/hindsight.env}"
    export HINDSIGHT_MODE="''${HINDSIGHT_MODE:-local_external}"
    export HINDSIGHT_BANK_ID="''${HINDSIGHT_BANK_ID:-hermes}"
    export HINDSIGHT_RECALL_BUDGET="''${HINDSIGHT_RECALL_BUDGET:-mid}"
    export HINDSIGHT_COMPOSE_PROJECT="$AI_PRESET-$AI_INSTANCE-hindsight"
    export HINDSIGHT_CONTAINER_NAME="$AI_PRESET-$AI_INSTANCE-hindsight"

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
