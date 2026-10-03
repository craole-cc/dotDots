{
  lib ? import <nixpkgs/lib>,
  #? The dotDots repository root, forwarded to the schemas so they can read the
  #? shared vocabulary data leaves under `Libraries/nix/lists/enums/data/`.
  #? Null when evaluating outside a checkout.
  sources ? null,
  ...
}: let
  inherit (lib.attrsets) recursiveUpdate;

  functions = import ./functions {inherit lib;};
  withFunctions = recursiveUpdate lib functions;

  inputs = import ./inputs {
    lix = recursiveUpdate withFunctions {
      inputs = lib.flake.inputs or null;
    };
  };
  withInputs = recursiveUpdate withFunctions inputs;

  schemas = import ./schemas {
    inherit sources;
    lix = withInputs;
  };
  withSchemas = recursiveUpdate withInputs {inherit schemas;};

  final = withSchemas;
in
  final
