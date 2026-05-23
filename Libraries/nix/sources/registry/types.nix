{_, ...}: let
  meta = let
    doc = ''
      Source registry types (Layer 1).

      Reusable NixOS/home-manager submodule types for the shared source-registry
      layer. These types describe the structural records produced by the shared
      registry helpers so module options can validate them explicitly.

      ## Types

      - `source.core` / `source.home`     - normalized source records
      - `registry.core` / `registry.home` - registry records with merged entries
      - `analysis.core` / `analysis.home` - grouped registry analysis views
    '';
    exports = {
      local = {inherit source registry analysis;};
      alias = {
        source_type = source;
        registry_type = registry;
        analysis_type = analysis;
      };
    };
  in {inherit doc exports;};

  inherit (_.options.construction) mkOption;
  inherit (_.types.combinators) attrsOf listOf nullOr submodule;
  inherit (_.types.primitives) anything bool path str;

  source = let
    common = submodule {
      options = {
        name = mkOption {
          description = "Normalized registry name";
          type = nullOr str;
          default = null;
        };
        path = mkOption {
          description = "Registry root path";
          type = nullOr path;
          default = null;
        };
        root = mkOption {
          description = "Registry root directory";
          type = nullOr path;
          default = null;
        };
        raw = mkOption {
          description = "Raw imported registry payload";
          type = anything;
          default = {};
        };
        value = mkOption {
          description = "Normalized registry value";
          type = anything;
          default = {};
        };
        stems = mkOption {
          description = "File stems used during source import";
          type = listOf str;
          default = ["data"];
        };
        recursive = mkOption {
          description = "Whether the registry import is recursive";
          type = bool;
          default = true;
        };
        extraArgs = mkOption {
          description = "Additional import arguments";
          type = attrsOf anything;
          default = {};
        };
      };
    };
  in {
    core = common;
    home = common;
  };

  analysis = let
    common = submodule {
      options = {
        groups = mkOption {
          description = "Grouped registry entries by field";
          type = attrsOf (attrsOf anything);
          default = {};
        };
        queries = mkOption {
          description = "Query views over grouped registry entries";
          type = attrsOf (attrsOf anything);
          default = {};
        };
      };
    };
  in {
    core = common;
    home = common;
  };

  registry = let
    common = submodule {
      options = {
        owner = mkOption {
          description = "Registry constructor owner label";
          type = str;
          default = "mkRegistry";
        };
        seed = mkOption {
          description = "Seed attrset merged into registry entries";
          type = attrsOf anything;
          default = {};
        };
        source = mkOption {
          description = "Normalized source record";
          type = source.core;
          default = {};
        };
        entries = mkOption {
          description = "Merged registry entries";
          type = attrsOf anything;
          default = {};
        };
        analysis = mkOption {
          description = "Grouped registry analysis";
          type = analysis.core;
          default = {};
        };
        groups = mkOption {
          description = "Grouped registry views";
          type = attrsOf (attrsOf anything);
          default = {};
        };
        queries = mkOption {
          description = "Query registry views";
          type = attrsOf (attrsOf anything);
          default = {};
        };
        name = mkOption {
          description = "Registry name";
          type = nullOr str;
          default = null;
        };
        path = mkOption {
          description = "Registry path";
          type = nullOr path;
          default = null;
        };
        raw = mkOption {
          description = "Raw registry payload";
          type = anything;
          default = {};
        };
        value = mkOption {
          description = "Resolved registry value";
          type = anything;
          default = {};
        };
      };
    };
  in {
    core = common;
    home = common;
  };
in
  meta.exports.local
  // {
    __docs = meta.doc;
    __rootAliases = meta.exports.alias;
  }
