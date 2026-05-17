{_, ...}: let
  meta = let
    doc = ''
      Style - Icons

      Registry, resolver, and types for icon theme configuration.

      ## Functions

      - `lookup`  - fuzzy lookup by registry key or alias, returns { key, entry } or null
      - `resolve` - takes pkgs + { light, dark } (string | package | { name, package })
                    returns { light, dark } each with { name, package }

      ## Types

      - `types.core` - NixOS submodule: { name, package }
      - `types.home` - home-manager submodule: { name, package }
    '';
    exports = {
      local = {
        inherit
          lookup
          resolve
          types
          ;
      };
      alias = {
        resolveIcons = resolve;
        lookupIcon = lookup;
      };
    };
  in {inherit doc exports;};

  inherit (_.attrsets.access) attrNames;
  inherit (_.attrsets.resolution) getPackage;
  inherit (_.content.empty) isEmpty isNotEmpty;
  inherit (_.lists.access) findFirst;
  inherit (_.lists.predicates) elem;
  inherit (_.options.construction) mkOption;
  inherit (_.types.combinators) submodule;
  inherit (_.types.predicates) isAttrs;
  inherit (_.types.primitives) package str;

  registry = _.style.filters.queries.icons.all;

  registryItems = map (key: {inherit key; entry = registry.${key};}) (attrNames registry);

  lookup = name:
    if isEmpty name
    then null
    else let
      byKey =
        if registry ? ${name}
        then {key = name; entry = registry.${name};}
        else null;
      byAlias =
        findFirst
        (item: elem name (item.entry.names.aliases or []))
        null
        registryItems;
    in
      if isNotEmpty byKey
      then byKey
      else byAlias;

  resolveOne = pkgs: input:
    if isEmpty input
    then {}
    else if isAttrs input && input ? package
    then input
    else if isAttrs input && input ? name
    then {
      inherit (input) name;
      package = getPackage {inherit pkgs; target = input.name;};
    }
    else let
      result = lookup input;
    in
      if isNotEmpty result
      then {
        name = result.key;
        package = getPackage {inherit pkgs; target = result.entry.names.package;};
      }
      else {
        name = input;
        package = getPackage {inherit pkgs; target = input;};
      };

  resolve = {
    pkgs,
    light ? {},
    dark ? {},
  }: {
    light = resolveOne pkgs light;
    dark  = resolveOne pkgs dark;
  };

  iconSubmodule = submodule {
    options = {
      name = mkOption {
        description = "Icon theme canonical registry key";
        type = str;
      };
      package = mkOption {
        description = "Icon theme package";
        type = package;
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
