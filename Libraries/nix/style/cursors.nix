{_, ...}: let
  meta = let
    doc = ''
      # Style - Cursors

      Registry, resolver, and types for cursor theme configuration.

      ## Data

      - `registry` - pure cursor theme entries keyed by canonical name

      ## Functions

      - `lookup`  - fuzzy lookup by registry key or alias, returns { key, entry } or null
      - `resolve` - takes pkgs + { light, dark, size, accent, variants }
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

  inherit (_.attrsets.access) attrNames;
  inherit (_.attrsets.construction) optionalAttrs;
  inherit (_.attrsets.merging) recursiveUpdate;
  inherit (_.attrsets.resolution) package;
  inherit (_.filesystem.importers) importAllMerged;
  inherit (_.lists.access) findFirst;
  inherit (_.lists.predicates) elem;
  inherit (_.options.construction) mkOption;
  inherit (_.strings.transformation) toPascal;
  inherit (_.types.combinators) submodule;
  inherit (_.types.predicates) int str isAttrs;

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
    variants ? {
      light = "latte";
      dark = "frappe";
    },
    size ? 24,
  }: let
    variant = variants.${polarity};
  in {
    name = "catppuccin-${variant}-${accent}-cursors";
    package = pkgs.catppuccin-cursors.${variant + (toPascal accent)};
    inherit size;
  };

  resolveOne = {
    pkgs,
    polarity,
    input,
    size ? null,
    accent ? null,
    variants ? null,
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
      size =
        if input ? size
        then input.size
        else if size != null
        then size
        else 24;
    }
    else let
      result = lookup input;
    in
      if result != null
      then
        if result.key == "catppuccin"
        then
          resolveCatppuccin (
            {inherit pkgs polarity;}
            // optionalAttrs (size != null) {inherit size;}
            // optionalAttrs (accent != null) {inherit accent;}
            // optionalAttrs (variants != null) {inherit variants;}
          )
        else {
          name = result.entry.names.${polarity} or result.key;
          package = package {
            inherit pkgs;
            target = result.entry.names.package;
          };
          size =
            if size != null
            then size
            else (result.entry.size or 24);
        }
      else {
        name = input;
        package = package {
          inherit pkgs;
          target = input;
        };
        size =
          if size != null
          then size
          else 24;
      };

  resolve = {
    pkgs,
    light ? {},
    dark ? {},
    size ? null,
    accent ? null,
    variants ? null,
  }: let
    args = polarity: input:
      {
        inherit pkgs polarity input;
      }
      // optionalAttrs (size != null) {inherit size;}
      // optionalAttrs (accent != null) {inherit accent;}
      // optionalAttrs (variants != null) {inherit variants;};
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
