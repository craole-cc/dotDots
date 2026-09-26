{
  lib ? import <nixpkgs/lib>,
  flakeInputs ? lib.flake.inputs or null,
  schema ? import ../schema,
  ...
}: let
  withLix = lix: {lix = lib.recursiveUpdate lib lix;};
  fetchers = import ./fetchers.nix {};
  trivial = import ./trivial.nix (withLix {});
  strings = import ./strings.nix (withLix {});
  debug = import ./debug.nix (withLix {inherit trivial strings;});
  schemas = import ./schemas.nix (withLix {inherit debug schema trivial;});
  inputs = import ./inputs.nix (
    {inputs = flakeInputs;}
    // (withLix {inherit fetchers;})
  );
  overlays = import ./overlays.nix {inherit inputs;};
  modules = import ./modules.nix ({
      inputs = flakeInputs;
      sources = inputs;
    }
    // (withLix {inherit fetchers;}));
in
  withLix {
    inherit
      debug
      fetchers
      schema
      schemas
      strings
      trivial
      modules
      overlays
      ;
  }
  // {inherit lib;}
