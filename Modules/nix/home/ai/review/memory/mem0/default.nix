{
  pkgs,
  cfg,
  ...
}: let
  inherit (pkgs) curl jq writeShellApplication;

  endpoint = "http://${cfg.bindAddress}:${toString cfg.mem0.port}";

  mem0 = writeShellApplication {
    name = "mem0";
    runtimeInputs = [
      curl
      jq
    ];
    text = ''
      printf '%s\n' 'Mem0 is exposed as an HTTP service; use mem0-status or mem0-verify.'
      printf '%s\n' 'Set MEM0_BASE_URL and use the REST API at that endpoint.'
    '';
  };

  status = writeShellApplication {
    name = "mem0-status";
    runtimeInputs = [
      curl
      jq
    ];
    text = ''
      endpoint="''${MEM0_BASE_URL:-${endpoint}}"
      if curl -fsS "$endpoint/openapi.json" -o /dev/null; then
        printf "Mem0 API: up (%s)\n" "$endpoint"
      else
        printf "Mem0 API: not responding (%s)\n" "$endpoint" >&2
        exit 1
      fi
    '';
  };

  verify = writeShellApplication {
    name = "mem0-verify";
    runtimeInputs = [
      curl
      jq
    ];
    text = ''
      endpoint="''${MEM0_BASE_URL:-${endpoint}}"
      curl -fsS "$endpoint/openapi.json" | jq -e '.paths | type == "object"' >/dev/null
      printf "Mem0 API OpenAPI document is valid at %s\n" "$endpoint"
    '';
  };
in {
  inherit mem0 status verify;

  packages = [
    mem0
    status
    verify
  ];

  env.MEM0_BASE_URL = endpoint;

  shellHook = ''
    if [ -t 1 ]; then
      printf "%s\n" "Mem0 shell: mem0, mem0-status, mem0-verify"
    fi
  '';
}
