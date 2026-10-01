{lib ? import <nixpkgs/lib>, ...}: let
  inherit (lib.attrsets) recursiveUpdate;

  args = import ./build;

  libraries = import ./libraries {inherit lib;};
  inherit (libraries) lix;
  inherit (lix.schema) mkHost;

  host = mkHost {inherit args;};
  infrastructure = import ./context (
    libraries // {inherit host;}
  );
in {
  imports = [
    ./build/hardware-configuration.nix
    ./modules
  ];

  _module.args = {
    lix = recursiveUpdate lix {inherit infrastructure;};
    inherit (libraries) lib;
  };
}
