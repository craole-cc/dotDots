{pkgs, ...}: let
  inherit (pkgs) curl jq writeShellApplication python3 docker docker-compose;

  hindsight = writeShellApplication {
    name = "hindsight";
    runtimeInputs = [
      curl
      jq
      python3
    ];
    text = ''
      printf '%s\n' 'Hindsight is exposed as an HTTP service; use hindsight-status or hindsight-verify.'
      printf '%s\n' 'Set HINDSIGHT_API_URL and HINDSIGHT_API_KEY to use the REST API.'
      printf '%s\n' 'CLI tools: hindsight, hindsight-retain, hindsight-recall, hindsight-reflect'
      printf '%s\n' 'Install with: pip install hindsight-client'
    '';
  };

  status = writeShellApplication {
    name = "hindsight-status";
    runtimeInputs = [
      curl
      jq
    ];
    text = ''
      endpoint="''${HINDSIGHT_API_URL:-https://api.hindsight.vectorize.io}"
      if curl -fsS "$endpoint/health" -o /dev/null; then
        printf "Hindsight API: up (%s)\n" "$endpoint"
      else
        printf "Hindsight API: not responding (%s)\n" "$endpoint" >&2
        exit 1
      fi
    '';
  };

  verify = writeShellApplication {
    name = "hindsight-verify";
    runtimeInputs = [
      curl
      jq
    ];
    text = ''
      endpoint="''${HINDSIGHT_API_URL:-https://api.hindsight.vectorize.io}"
      curl -fsS "$endpoint/openapi.json" | jq -e '.paths | type == "object"' >/dev/null
      printf "Hindsight API OpenAPI document is valid at %s\n" "$endpoint"
    '';
  };

  # Transitional secret loading: migrate this to SOPS + age-backed host provisioning.
  # Keep plaintext outside Git; the eventual NixOS/Home Manager service should
  # consume a sops-nix-provisioned runtime secret instead.
  devShell = {
    name = "dots-ai-hindsight";
    packages = [
      docker
      docker-compose
      curl
      jq
      python3
    ];
    env = {};
    shellHook = ''
            export HINDSIGHT_DATA_DIR="''${HOME}/data/hindsight"
            export HINDSIGHT_SECRETS_FILE="''${HINDSIGHT_SECRETS_FILE:-$HOME/Private/hindsight.env}"
            if [ -r "$HINDSIGHT_SECRETS_FILE" ]; then
              set -a
              . "$HINDSIGHT_SECRETS_FILE"
              set +a
            fi
            export HINDSIGHT_API_URL="''${HINDSIGHT_API_URL:-http://100.90.252.109:8888}"
            export HINDSIGHT_BIND_ADDRESS="''${HINDSIGHT_BIND_ADDRESS:-100.90.252.109}"
            export HINDSIGHT_LLM_BASE_URL="''${HINDSIGHT_LLM_BASE_URL:-http://100.76.128.70:20128/v1}"
            export HINDSIGHT_LLM_MODEL="''${HINDSIGHT_LLM_MODEL:-auto/best-fast}"
            export HINDSIGHT_REFLECT_LLM_MODEL="''${HINDSIGHT_REFLECT_LLM_MODEL:-auto/best-chat}"
            export HINDSIGHT_API_WORKER_ID="''${HINDSIGHT_API_WORKER_ID:-hindsight-victus}"

            _hindsight_compose() {
              cat <<'EOF'
      services:
        hindsight:
          image: ghcr.io/vectorize-io/hindsight:latest
          container_name: hindsight
          restart: unless-stopped
          ports:
            - "''${HINDSIGHT_BIND_ADDRESS}:8888:8888"
            - "''${HINDSIGHT_BIND_ADDRESS}:9999:9999"
            - "''${HINDSIGHT_BIND_ADDRESS}:8889:8889"
          environment:
            - HINDSIGHT_API_LLM_API_KEY=''${HINDSIGHT_API_LLM_API_KEY:-}
            - HINDSIGHT_API_LLM_PROVIDER=openai
            - HINDSIGHT_API_LLM_BASE_URL=''${HINDSIGHT_LLM_BASE_URL}
            - HINDSIGHT_API_LLM_MODEL=''${HINDSIGHT_LLM_MODEL}
            - HINDSIGHT_API_RETAIN_LLM_MODEL=''${HINDSIGHT_LLM_MODEL}
            - HINDSIGHT_API_CONSOLIDATION_LLM_MODEL=''${HINDSIGHT_LLM_MODEL}
            - HINDSIGHT_API_REFLECT_LLM_MODEL=''${HINDSIGHT_REFLECT_LLM_MODEL}
            - HINDSIGHT_API_WORKER_ID=''${HINDSIGHT_API_WORKER_ID}
            - HINDSIGHT_API_EMBEDDINGS_PROVIDER=openai
            - HINDSIGHT_API_EMBEDDINGS_MODEL=text-embedding-3-small
          volumes:
            - ''${HINDSIGHT_DATA_DIR}:/home/hindsight/.pg0
          healthcheck:
            test: ["CMD", "curl", "-f", "http://localhost:8888/health"]
            interval: 30s
            timeout: 10s
            retries: 3
      EOF
            }

            hindsight-up() {
              mkdir -p "''${HINDSIGHT_DATA_DIR}"
              _hindsight_compose | docker compose -f /dev/stdin up -d
              echo "Hindsight starting..."
              sleep 5
              docker compose -f <(_hindsight_compose) ps
            }

            hindsight-down() {
              _hindsight_compose | docker compose -f /dev/stdin down
            }

            hindsight-logs() {
              docker logs -f hindsight
            }

            hindsight-status() {
              curl -sf "''${HINDSIGHT_API_URL}/health" && echo "up" || echo "down"
            }

            hindsight-bank-create() {
              local bank_id="$1"
              local config_file="$2"
              if [[ ! -f "$config_file" ]]; then
                echo "Usage: hindsight-bank-create <bank_id> <config.json>"
                return 1
              fi
              cat "$config_file" | docker exec -i hindsight hindsight-api bank create --config /dev/stdin
            }

            hindsight-bank-list() {
              docker exec hindsight hindsight-api bank list
            }

            if [ -t 1 ]; then
              printf "%s\n" "Hindsight management shell: ai-hindsight"
              printf "%s\n" "  hindsight-up         Start Hindsight server"
              printf "%s\n" "  hindsight-down       Stop Hindsight server"
              printf "%s\n" "  hindsight-status     Check health"
              printf "%s\n" "  hindsight-logs       Follow logs"
              printf "%s\n" "  hindsight-bank-create <bank_id> <config.json>"
              printf "%s\n" "  hindsight-bank-list  List banks"
              printf "%s\n" "API URL: $HINDSIGHT_API_URL"
            fi
    '';
  };
in {
  inherit hindsight status verify devShell;

  packages = [
    hindsight
    status
    verify
    python3
  ];

  env = {
    HINDSIGHT_API_URL = "http://100.90.252.109:8888";
    HINDSIGHT_API_KEY = "";
    HINDSIGHT_BANK_ID = "Hermes";
    HINDSIGHT_BUDGET = "mid";
    HINDSIGHT_MODE = "cloud";
    HINDSIGHT_TIMEOUT = "120";
    HINDSIGHT_IDLE_TIMEOUT = "300";
  };

  shellHook = ''
    if [ -t 1 ]; then
      printf "%s\n" "Hindsight shell: hindsight, hindsight-status, hindsight-verify"
      printf "%s\n" "API URL: $HINDSIGHT_API_URL (Victus Tailscale)"
      printf "%s\n" "Set HINDSIGHT_API_KEY in ~/.hermes/.env or environment"
      printf "%s\n" "Install CLI: pip install hindsight-client"
      printf "%s\n" "Management shell: nix develop .#ai-hindsight"
    fi
  '';
}
