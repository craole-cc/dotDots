{lib ? import <nixpkgs/lib>, ...}: let
  inherit (lib.attrsets) recursiveUpdate;

  mkLix = extensions: {lix = recursiveUpdate lib extensions;};

  functions = import ./functions {
    inherit mkLix;
    inherit (mkLix {}) lix;
  };
  withFunctions = mkLix functions;

  sources = import ./sources {
    inherit mkLix;
    lix = recursiveUpdate withFunctions.lix {
      inputs = lib.flake.inputs or null;
    };
  };
  withSources = mkLix (withFunctions.lix // sources);

  types = import ./types {
    inherit mkLix;
    inherit (withSources) lix;
  };
  withTypes = mkLix (withSources.lix // {inherit types;});
in
  withTypes.lix
