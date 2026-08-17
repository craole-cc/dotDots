args: let
  agentPackages = import ./sources.nix args;
  gateway = import ./gateway.nix args;
in {
  inherit (gateway) env;
  packages = gateway.packages ++ agentPackages;
  inherit (gateway) shellHook;
}
