{agents, ...}:
import ./lib.nix {
  name = "hermes";
  components = [agents.hermes];
}
