{_, ...}: let
  meta = let
    # TODO: Update the docs
    doc = ''
      Style registry data (Layer 0).

      Provides normalized style records from `./data`, with consistent
      `categories` fields. Supplies primitive tree inspection for recursive
      processing, validated registry lookup, registry-derived identification
      metadata, and shared resolution helpers used by higher style layers.

      Depends on: sources.registry.importer.
    '';

    exports = let
      internal = let
        functions = {inherit mkRegistry mkAnalysis;};
        aliases = {};
      in
        {inherit functions aliases;} // functions // aliases;

      external = {
        inherit (internal) mkRegistry;
      };
    in {inherit internal external;};
  in {inherit doc exports;};

  inherit (_.sources.registry.resolution) normalize lookup;
  # inherit (_.content.emptiness) isNotEmpty;
  # inherit (_.debug.assertions) withContext;
  # inherit (_.filesystem.importers) importRegistry;
  # inherit (_.strings.construction) concat;
  # inherit (_.strings.transformation) wrap;
  # inherit (_.strings.predicates) isValidPosixName;
  # inherit (_.types.predicates) isAttrs isPath isString;

  # TODO: Add the nix-style documentation with headings input, return, dependencies, type and examples
  # TODO: Implement registry orchestrator
  mkRegistry = {source}: let
    utils = {
      set = args: normalize args;
      get = args: lookup args;
    };
    data = let
      entries = source.raw;
      analysis = mkAnalysis {inherit entries;};
    in {
      inherit entries;
      inherit (analysis) groups queries;
    };
  in {inherit data utils;};

  # TODO: Add the nix-style documentation with headings input, return, dependencies, type and examples
  mkAnalysis = {}: let
    groups = {};
    queries = {};
  in {inherit groups queries;};
in
  with meta.exports;
    internal
    // {
      __rootAliases = external;
      __docs = meta.doc;
    }
