{
  _,
  lib,
  ...
}: let
  meta = let
    doc = ''
      # Style - Cursors

      Registry, resolver, and types for cursor theme configuration.

      ## Data

      - `registry` - pure cursor theme entries keyed by canonical name

      ## Functions

      - `lookup`  - fuzzy lookup by registry key or alias, returns { key, entry } or null
      - `resolve` - takes pkgs + { light, dark, size, accent, variant }
                    returns { light, dark } each with { name, package, size }

      ## Types

      - `types.core` - NixOS submodule: { name, package, size }
      - `types.home` - home-manager submodule: { name, package, size }
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
        resolveCursors = resolve;
        lookupCursor = lookup;
        cursorRegistry = registry;
      };
    };
  in {inherit doc exports;};

  inherit (_.attrsets.resolution) package;
  inherit (_.filesystem.importers) importAllMerged;
  inherit (_.lists.predicates) elem;
  inherit (_.types.predicates) isAttrs isString;
  inherit (lib.attrsets) attrNames optionalAttrs recursiveUpdate;
  inherit (lib.lists) findFirst;
  inherit (lib.options) mkOption;
  inherit (lib.types) either int nullOr str submodule;

  registry = importAllMerged ./data {};

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

  resolveCatppuccin = {
    pkgs,
    polarity,
    accent ? "teal",
    variant ? {
      light = "latte";
      dark = "frappe";
    },
    size ? 24,
  }: let
    toPascal = str:
      lib.strings.toUpper (lib.strings.substring 0 1 str)
      + lib.strings.substring 1 (-1) str;
    activeVariant = variant.${polarity};
  in {
    name = "catppuccin-${activeVariant}-${accent}-cursors";
    package = pkgs.catppuccin-cursors.${activeVariant + (toPascal accent)};
    inherit size;
  };

  resolveOne = {
    pkgs,
    polarity,
    input,
    size ? null,
    accent ? null,
    variant ? null,
  }:
    if isAttrs input && input ? package
    then input
    else if isAttrs input && input ? name
    then {
      inherit (input) name;
      package = package {
        inherit pkgs;
        target = input.name;
      };
      size = input.size or size or 24;
    }
    else let
      result = lookup input;
    in
      if result != null
      then
        if result.key == "catppuccin"
        then
          resolveCatppuccin (
            {inherit pkgs polarity size;}
            // optionalAttrs (accent != null) {inherit accent;}
            // optionalAttrs (variant != null) {inherit variant;}
          )
        else {
          name = result.entry.names.${polarity} or result.key;
          package = package {
            inherit pkgs;
            target = result.entry.names.package;
          };
          size = size or result.entry.size or 24;
        }
      else {
        name = input;
        package = package {
          inherit pkgs;
          target = input;
        };
        size = size or 24;
      };

  resolve = {
    pkgs,
    light ? {},
    dark ? {},
    size ? null,
    accent ? null,
    variant ? null,
  }: let
    args = polarity: input:
      {
        inherit pkgs polarity input;
      }
      // optionalAttrs (size != null) {inherit size;}
      // optionalAttrs (accent != null) {inherit accent;}
      // optionalAttrs (variant != null) {inherit variant;};
  in
    recursiveUpdate {
      light = resolveOne (args "light" light);
      dark = resolveOne (args "dark" dark);
    } {};

  cursorSubmodule = submodule {
    options = {
      name = mkOption {
        description = "Cursor theme name";
        type = str;
      };
      package = mkOption {
        description = "Cursor theme package";
        type = lib.types.package;
      };
      size = mkOption {
        description = "Cursor size in pixels";
        type = int;
        default = 24;
      };
    };
  };

  types = {
    core = cursorSubmodule;
    home = cursorSubmodule;
  };
in
  meta.exports.local
  // {
    __docs = meta.doc;
    __rootAliases = meta.exports.alias;
  }
