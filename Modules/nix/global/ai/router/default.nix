args: let
  agentPackages = import ./sources.nix args;
  gateway = import ./gateway.nix args;
in {
  env = gateway.env;
  packages = gateway.packages ++ agentPackages;
  shellHook = gateway.shellHook;
}
