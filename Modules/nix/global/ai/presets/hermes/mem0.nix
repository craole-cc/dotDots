{
  agents,
  memory,
  cfg,
  lix,
  paths,
  ...
}:
import ./lib.nix {
  inherit cfg lix paths;
  name = "hermes-mem0";
  components = [
    memory.mem0
    agents.hermes
  ];

  init = ''
    export MEM0_PORT="$(( ${toString cfg.mem0.port} + AI_PORT_OFFSET ))"
    export MEM0_BASE_URL="http://$AI_BIND_ADDRESS:$MEM0_PORT"
    export MEM0_HOST="$MEM0_BASE_URL"
  '';

  start = ''
    hermes config set memory.provider mem0 || true
  '';
}
