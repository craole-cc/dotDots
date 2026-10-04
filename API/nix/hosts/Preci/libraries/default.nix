{lib ? import <nixpkgs/lib>, ...}: let
  inherit (lib.attrsets) recursiveUpdate;

  mkLix = extensions: {lix = recursiveUpdate lib extensions;};

  functions = import ./functions {
    inherit mkLix;
    inherit (mkLix {}) lix;
  };
  withFunctions = mkLix functions;

  inputs = import ./packages {
    inherit mkLix;
    lix = recursiveUpdate withFunctions.lix {
      inputs = lib.flake.inputs or null;
    };
  };
  withInputs = mkLix (withFunctions.lix // inputs);

  types = import ./types {
    inherit mkLix;
    inherit (withInputs) lix;
  };
  withTypes = mkLix (withInputs.lix // {inherit types;});
in
  withTypes.lix
