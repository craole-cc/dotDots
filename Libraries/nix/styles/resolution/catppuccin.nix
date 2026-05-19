{_, ...}: let
  meta = let
    doc = ''
      catppuccin - registry-driven accent/flavor resolution plus cursor and theme
      builders for the Catppuccin family.
    '';
    exports = {
      local = {inherit accents flavors cursor cursors theme themes resolve defaults;};
      alias = {};
    };
  in {inherit doc exports;};

  # inherit () attrNames attrValues elem foldl' listToAttrs map;
  inherit (_.attrsets.access) attrNames;
  inherit (_.attrsets.resolution) getPackage;
  inherit (_.strings.transformation) toLowerCase toTitleCase toPascalCase;
  inherit (_.lists.predicates) isIn;
  inherit (_.lists.aggregation) foldl';
  inherit (_.lists.access) head;
  inherit (_.lists.selection) filter;
  inherit (_.attrsets.construction) listToAttrs;

  #  Accent registry
  accents = let
    registry = _.styles.filters.queries.accents.all;
    names = attrNames registry;
    aliases =
      foldl' (
        acc: name:
          acc
          // listToAttrs (map (a: {
              name = a;
              value = name;
            })
            (registry.${name}.aliases or []))
      ) {}
      names;
    check = input: let
      value = toLowerCase input;
      normalized = aliases.${value} or value;
    in
      if isIn normalized names
      then normalized
      else throw "Invalid accent `${input}`. Valid: ${toString names}";
  in {inherit registry names aliases check;};

  #  Flavor registry
  flavors = let
    registry = _.styles.filters.queries.flavors.all;
    names = attrNames registry;
    aliases =
      foldl' (
        acc: name:
          acc
          // listToAttrs (map (a: {
              name = a;
              value = name;
            })
            (registry.${name}.aliases or []))
      ) {}
      names;
    check = input: let
      value = toLowerCase input;
      normalized = aliases.${value} or value;
    in
      if isIn normalized names
      then normalized
      else throw "Invalid flavor `${input}`. Valid: ${toString names}";
    # Convenience: which flavor names are light/dark
    light = filter (n: registry.${n}.polarity == "light") names;
    dark = filter (n: registry.${n}.polarity == "dark") names;
  in {inherit registry names aliases check light dark;};

  #  Cursor builder
  # Returns { light, dark } each { name, package, size }
  cursor = {
    accent ? "blue",
    flavor ? null, # if provided, drives the dark variant
    size ? 24,
    pkgs,
  }: let
    a = accents.check accent;
    titleA = toTitleCase a;
    darkFlavor =
      if flavor != null
      then flavors.check flavor
      else "mocha";
    lightFlavor = head flavors.light;
    mkName = fl: "catppuccin-${fl}-${a}-cursors";
    mkPkg = fl:
      getPackage {
        inherit pkgs;
        target = "catppuccin-cursors.${fl}${toPascalCase a}"; #TODO: check this
      };
  in {
    light = {
      name = mkName lightFlavor;
      package = mkPkg lightFlavor;
      inherit size;
    };
    dark = {
      name = mkName darkFlavor;
      package = mkPkg darkFlavor;
      inherit size;
    };
  };

  #  Cursors (list form)
  cursors = args: let
    result = cursor args;
  in [result.light result.dark];

  #  Theme builder
  # Returns { light, dark } each { name, scheme, package, polarity }
  theme = {
    accent ? "blue",
    size ? null,
    pkgs,
  }: let
    a = accents.check accent;
    mkVariant = fl: let
      entry = _.styles.filters.queries.themes.all.${"catppuccin-${fl}"} or
        (throw "No catppuccin theme entry for flavor `${fl}`");
    in {
      name = entry.name;
      scheme = entry.scheme;
      package = _.attrsets.resolution.getPackage {
        inherit pkgs;
        target = entry.package;
      };
      polarity = entry.polarity;
    };
    lightFlavor = head flavors.light;
    darkFlavor = "mocha";
  in {
    light = mkVariant lightFlavor;
    dark = mkVariant darkFlavor;
  };

  #  Themes (list form) - was wrongly calling cursor, now calls theme
  themes = args: let
    result = theme args;
  in [result.light result.dark];

  #  Defaults
  defaults = {
    accent = "blue";
    flavor = "mocha";
    size = 24;
  };

  #  Resolve (high-level)
  resolve = {
    accent ? defaults.accent,
    flavor ? defaults.flavor,
    size ? defaults.size,
    pkgs,
  }: {
    cursors = cursor {inherit accent flavor size pkgs;};
    themes = theme {inherit accent pkgs;};
    accent = accents.check accent;
    flavor = flavors.check flavor;
  };
in
  meta.exports.local
  // {
    __docs = meta.doc;
    __rootAliases = meta.exports.alias;
  }
