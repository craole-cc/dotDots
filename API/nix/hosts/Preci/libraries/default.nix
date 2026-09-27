{
  lib ? import <nixpkgs/lib>,
  flakeInputs ? lib.flake.inputs or null,
  ...
}: let
  inherit (lib.attrsets) recursiveUpdate;

  lix =
    recursiveUpdate
    (import ./functions {inherit lib;})
    {inputs = flakeInputs;};

  inputs = import ./inputs {inherit lib lix;};

  schemas = import ./schemas {
    inherit lib;
    lix = recursiveUpdate lix {inputs = flakeInputs;};
  };
in {
  lix =
    recursiveUpdate
    (recursiveUpdate lix inputs)
    schemas;
  inherit lib;
}
