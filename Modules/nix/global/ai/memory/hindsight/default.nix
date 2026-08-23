{pkgs, ...}: let
  inherit (pkgs) curl jq writeShellApplication python3;

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
in {
  inherit hindsight status verify;

  packages = [
    hindsight
    status
    verify
    python3
  ];

  env = {
    # Point to Victus over Tailscale for Phase 2 deployment
    HINDSIGHT_API_URL = "http://100.90.252.109:8888";
    HINDSIGHT_API_KEY = "";
    HINDSIGHT_BANK_ID = "hermes";
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
    fi
  '';
}
