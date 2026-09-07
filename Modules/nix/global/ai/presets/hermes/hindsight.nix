{
  agents,
  memory,
  ...
}:
import ./lib.nix {
  name = "hermes-hindsight";
  components = [
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
