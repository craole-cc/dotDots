{
  agents,
  cfg,
  paths,
  ...
}:
import ./lib.nix {
  inherit cfg paths;
  name = "hermes";
  components = [agents.hermes];
}
