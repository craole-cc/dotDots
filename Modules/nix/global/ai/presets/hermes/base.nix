{
  agents,
  cfg,
  lix,
  paths,
  ...
}:
import ./lib.nix {
  inherit cfg lix paths;
  name = "hermes";
  components = [agents.hermes];
}
