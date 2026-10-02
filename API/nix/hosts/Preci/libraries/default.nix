{
  lib ? import <nixpkgs/lib>,
  flakeInputs ? lib.flake.inputs or null,
  #? The dotDots repository root, forwarded to the schemas so they can read the
  #? shared vocabulary data leaves under `Libraries/nix/lists/enums/data/`.
  #? Null when evaluating outside a checkout.
  sources ? null,
  ...
}: let
  inherit (lib.attrsets) recursiveUpdate;

  lix =
    recursiveUpdate
    (import ./functions {inherit lib;})
    {inputs = flakeInputs;};

  inputs = import ./inputs {inherit lib lix;};

  schemas = import ./schemas {
    inherit lib sources;
    lix = recursiveUpdate lix {inputs = flakeInputs;};
  };
in {
  lix =
    recursiveUpdate
    (recursiveUpdate lix inputs)
    schemas;
  inherit lib;
}
