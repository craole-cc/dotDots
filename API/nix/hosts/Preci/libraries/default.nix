{lib ? import <nixpkgs/lib>, ...}: let
  inherit (lib.attrsets) recursiveUpdate;

  mkLix = extensions: {lix = recursiveUpdate lib extensions;};

  functions = import ./functions {
    inherit mkLix;
    lix = mkLix {};
  };
  withFunctions = mkLix functions;

  inputs = import ./inputs {
    inherit mkLix;
    lix = recursiveUpdate withFunctions.lix {
      inputs = lib.flake.inputs or null;
    };
  };
  withInputs = mkLix (withFunctions.lix // inputs);

  schemas = import ./schemas {
    inherit mkLix;
    inherit (withInputs) lix;
  };
  withSchemas = mkLix (withInputs.lix // {inherit schemas;});
in
  withSchemas.lix
