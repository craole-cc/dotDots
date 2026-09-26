{lib, ...}: let
  host = import ./host.nix;
  lix = import ./lib.nix {inherit lib;};
  inputs = import ./sources.nix {
    inherit lix;
    inherit (host) system;
    inputs = lib.flake.inputs or {};
  };
  resolved = lix.mkHost host;
in {
  imports =
    [./hardware-configuration]
    ++ (with inputs; [
      home-manager
      nix-index
      catppuccin
    ])
    ++ [./resolve];

  _module.args = {
    inherit host lix inputs resolved;
  };
}
