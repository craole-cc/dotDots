{
  _,
  lib,
  ...
}: let
  meta = let
    doc = ''
      # Style - Icons

      Registry, resolver, and types for icon theme configuration.

      ## Data

      - `registry` - pure icon theme entries keyed by canonical name

      ## Functions

      - `lookup`  - fuzzy lookup by registry key or alias, returns { key, entry } or null
      - `resolve` - takes `pkgs` + `{ light, dark }` (string | package | { name, package })
                    returns `{ light, dark }` each with `{ name, package }`

      ## Types

      - `types.core` - NixOS submodule: `{ name, package }`
      - `types.home` - home-manager submodule: `{ name, package }`
    '';
    exports = {
      local = {
        inherit
          lookup
          registry
          resolve
          types
          ;
      };
      alias = {
        resolveIcons = resolve;
        lookupIcon = lookup;
        iconRegistry = registry;
      };
    };
  in {inherit doc exports;};

  inherit (_.attrsets.resolution) package;
  inherit (_.filesystem.importers) importAllMerged;
  inherit (_.lists.predicates) elem;
  inherit (_.types.predicates) isAttrs isString;
  inherit (lib.attrsets) attrNames;
  inherit (lib.lists) findFirst;
  inherit (lib.options) mkOption;
  inherit (lib.types) str submodule;

  registry = importAllMerged ./data/icons.nix {};

  registryItems = map (key: {
    inherit key;
    entry = registry.${key};
  }) (attrNames registry);

  lookup = name: let
    byKey =
      if registry ? ${name}
      then {
        key = name;
        entry = registry.${name};
      }
      else null;
    byAlias =
      findFirst
      (item: elem name (item.entry.names.aliases or []))
      null
      registryItems;
  in
    if byKey != null
    then byKey
    else byAlias;

  resolveOne = pkgs: input:
    if isAttrs input && input ? package
    then input
    else if isAttrs input && input ? name
    then {
      inherit (input) name;
      package = package {
        inherit pkgs;
        target = input.name;
      };
    }
    else let
      result = lookup input;
    in
      if result != null
      then {
        name = result.key;
        package = package {
          inherit pkgs;
          target = result.entry.names.package;
        };
      }
      else {
        name = input;
        package = package {
          inherit pkgs;
          target = input;
        };
      };

  resolve = {
    pkgs,
    light ? {},
    dark ? {},
  }: {
    light = resolveOne pkgs light;
    dark = resolveOne pkgs dark;
  };

  iconSubmodule = submodule {
    options = {
      name = mkOption {
        description = "Icon theme canonical registry key";
        type = str;
      };
      package = mkOption {
        description = "Icon theme package";
        type = lib.types.package;
      };
    };
  };

  types = {
    core = iconSubmodule;
    home = iconSubmodule;
  };
in
  meta.exports.local
  // {
    __docs = meta.doc;
    __rootAliases = meta.exports.alias;
  }
