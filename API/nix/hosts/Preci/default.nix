{lib, ...}: let
  args = import ./args.nix;
  lix = import ./lib {inherit lib;};
  inputs = import ./inputs {
    inherit lix;
    inherit (args) system;
    inputs = lib.flake.inputs or {};
  };
  resolved = lix.mkHost args;
in {
  imports =
    [./hardware-configuration]
    ++ (with inputs; [
      home-manager
      nix-index
      catppuccin
    ])
    ++ [./outputs];

  _module.args = {
    inherit args lix inputs resolved;
  };
}
