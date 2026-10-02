{
  lib ? import <nixpkgs/lib>,
  #? The dotDots repository root. The schemas read the shared vocabulary data
  #? leaves under `Libraries/nix/lists/enums/data/` relative to this, so that
  #? the host schema and the legacy `_` tree validate against one vocabulary
  #? rather than two that drift. Overridable so an out-of-tree caller can point
  #? at a different checkout.
  sources ? ../../../..,
  ...
}: let
  inherit (lib.attrsets) recursiveUpdate;

  args = import ./build;

  libraries = import ./libraries {inherit lib sources;};
  inherit (libraries) lix;
  inherit (lix.schemas) mkHost;

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
