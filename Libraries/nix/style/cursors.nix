{_, ...}: let
  meta = let
    doc = ''
      Style - Cursors

      Registry, resolver, and types for cursor theme configuration.

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
          resolve
          types
          ;
      };
      alias = {
        resolveCursors = resolve;
        lookupCursor = lookup;
      };
    };
  in {inherit doc exports;};

  inherit (_.attrsets.access) attrNames;
  inherit (_.attrsets.construction) optionalAttrs;
  inherit (_.attrsets.resolution) getPackage;
  inherit (_.content.empty) isEmpty isNotEmpty;
  inherit (_.lists.access) findFirst;
  inherit (_.lists.predicates) elem;
  inherit (_.options.construction) mkOption;
  inherit (_.strings.transformation) toPascal;
  inherit (_.types.combinators) submodule;
  inherit (_.types.predicates) isAttrs;
  inherit (_.types.primitives) int package str;

  registry = _.style.filters.queries.cursors.all;

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

  resolveCatppuccin = {
    pkgs,
    polarity,
    accent ? "teal",
    variants ? {light = "latte"; dark = "frappe";},
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
  }: let
    catppuccinArgs =
      {inherit pkgs polarity;}
      // optionalAttrs (isNotEmpty size) {inherit size;}
      // optionalAttrs (isNotEmpty accent) {inherit accent;}
      // optionalAttrs (isNotEmpty variants) {inherit variants;};
  in
    if isEmpty input
    then resolveCatppuccin catppuccinArgs
    else if isAttrs input && input ? package
    then input
    else if isAttrs input && input ? name
    then {
      inherit (input) name;
      package = getPackage {inherit pkgs; target = input.name;};
      size =
        if input ? size
        then input.size
        else if isNotEmpty size
        then size
        else 24;
    }
    else let
      result = lookup input;
    in
      if isNotEmpty result
      then
        if result.key == "catppuccin"
        then resolveCatppuccin catppuccinArgs
        else {
          name = result.entry.names.${polarity} or result.key;
          package = getPackage {inherit pkgs; target = result.entry.names.package;};
          size =
            if isNotEmpty size
            then size
            else (result.entry.size or 24);
        }
      else {
        name = input;
        package = getPackage {inherit pkgs; target = input;};
        size = if isNotEmpty size then size else 24;
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
      {inherit pkgs polarity input;}
      // optionalAttrs (isNotEmpty size) {inherit size;}
      // optionalAttrs (isNotEmpty accent) {inherit accent;}
      // optionalAttrs (isNotEmpty variants) {inherit variants;};
  in {
    light = resolveOne (args "light" light);
    dark  = resolveOne (args "dark" dark);
  };

  cursorSubmodule = submodule {
    options = {
      name = mkOption {
        description = "Cursor theme name";
        type = str;
      };
      package = mkOption {
        description = "Cursor theme package";
        type = package;
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
