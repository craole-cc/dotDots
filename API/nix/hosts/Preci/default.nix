{...}: let
  args = import ./args.nix;
  lix = import ./lib {};
  inputs = import ./inputs {
    inherit lix;
    inherit (args) system;
  };
  host = lix.mkHost args;
in {
  imports = [
    ./hardware-configuration
    inputs.home-manager
    inputs.nix-index
    inputs.catppuccin
    ./outputs
  ];

  _module.args = {
    inherit host lix inputs;
  };
}
