{pkgs, HOME ? "/home/craole", ...}: let
  inherit (pkgs) coreutils curl docker jq writeShellApplication;
  secretsFile = "${HOME}/Private/hindsight.env";

  compose = writeShellApplication {
    name = "hindsight-compose";
    runtimeInputs = [coreutils];
    text = ''
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
            - HINDSIGHT_API_LLM_API_KEY=''${HINDSIGHT_API_LLM_API_KEY}
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
    '';
  };

  up = writeShellApplication {
    name = "hindsight-up";
    runtimeInputs = [coreutils docker];
    text = ''
      secrets_file="''${HINDSIGHT_SECRETS_FILE:-${secretsFile}}"
      if [ ! -r "$secrets_file" ]; then
        printf 'Hindsight secrets file is not readable: %s\n' "$secrets_file" >&2
        exit 1
      fi
      set -a
      # shellcheck disable=SC1090
      . "$secrets_file"
      set +a
      : "''${HINDSIGHT_API_LLM_API_KEY:?HINDSIGHT_API_LLM_API_KEY is required}"
      mkdir -p "''${HINDSIGHT_DATA_DIR}"
      hindsight-compose | docker compose -f /dev/stdin up -d
      printf '%s\n' 'Hindsight starting...'
      sleep 5
      hindsight-compose | docker compose -f /dev/stdin ps
    '';
  };

  down = writeShellApplication {
    name = "hindsight-down";
    runtimeInputs = [docker];
    text = ''
      hindsight-compose | docker compose -f /dev/stdin down
    '';
  };

  logs = writeShellApplication {
    name = "hindsight-logs";
    runtimeInputs = [docker];
    text = ''
      exec docker logs -f hindsight
    '';
  };

  status = writeShellApplication {
    name = "hindsight-status";
    runtimeInputs = [curl];
    text = ''
      endpoint="''${HINDSIGHT_API_URL}"
      curl -fsS "$endpoint/health"
      printf '\n'
    '';
  };

  verify = writeShellApplication {
    name = "hindsight-verify";
    runtimeInputs = [curl jq];
    text = ''
      endpoint="''${HINDSIGHT_API_URL}"
      curl -fsS "$endpoint/openapi.json" | jq -e '.paths | type == "object"' >/dev/null
      printf 'Hindsight API OpenAPI document is valid at %s\n' "$endpoint"
    '';
  };

  bankCreate = writeShellApplication {
    name = "hindsight-bank-create";
    runtimeInputs = [docker];
    text = ''
      bank_id="''${1:?Usage: hindsight-bank-create <bank_id> <config.json>}"
      config_file="''${2:?Usage: hindsight-bank-create <bank_id> <config.json>}"
      test -f "$config_file"
      docker exec -i hindsight hindsight-api bank create --bank-id "$bank_id" --config /dev/stdin < "$config_file"
    '';
  };

  bankList = writeShellApplication {
    name = "hindsight-bank-list";
    runtimeInputs = [docker];
    text = ''
      exec docker exec hindsight hindsight-api bank list
    '';
  };
in {
  packages = [compose up down logs status verify bankCreate bankList];
}
