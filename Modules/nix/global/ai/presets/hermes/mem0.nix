{
  agents,
  memory,
  ...
}:
import ./lib.nix {
  name = "hermes-mem0";
  components = [
    memory.mem0
    agents.hermes
  ];

  init = ''
    export MEM0_PORT="$((8888 + AI_PORT_OFFSET))"
    export MEM0_BASE_URL="http://$AI_BIND_ADDRESS:$MEM0_PORT"
    export MEM0_HOST="$MEM0_BASE_URL"
  '';

  start = ''
    hermes config set memory.provider mem0 || true
  '';
}
