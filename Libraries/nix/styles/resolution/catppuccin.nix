{_, ...}: let
  meta = let
    doc = ''
      Catppuccin resolution (Layer 3).

      Registry-driven accent/flavor validation plus cursor and theme builders
      for the Catppuccin family. Provides namespaced accent/flavor records with
      check functions, and high-level resolve entry point.

      Depends on: styles.filters, attrsets.resolution, strings.transformation.
    '';
    exports = {
      local = {
        inherit
          mkCursor
          mkCursors
          mkTheme
          mkThemes
          resolve
          ;
        inherit (data) accents flavors;
      };
      alias = {
        mkCatppuccinCursor = mkCursor;
        mkCatppuccinCursors = mkCursors;
        mkCatppuccinTheme = mkTheme;
        mkCatppuccinThemes = mkThemes;
        catppuccinFlavors = data.flavors;
        catppuccinAccents = data.accents;
        mkCatppuccin = resolve;
        catppuccin = exports.local;
      };
    };
  in {inherit doc exports;};

  inherit (_.attrsets.access) attrNames;
  inherit (_.attrsets.construction) listToAttrs;
  inherit (_.attrsets.resolution) getPackage;
  inherit (_.lists.access) head;
  inherit (_.lists.aggregation) foldl';
  inherit (_.lists.predicates) isIn;
  inherit (_.lists.selection) filter;
  inherit (_.strings.transformation) toLowerCase toPascalCase;
  inherit (_.debug.assertions) withContext;

  seed = {
    accent = {
      light = "sapphire";
      dark = "sky";
    };
    flavor = {
      light = "latte";
      dark = "frappe";
    };
    size = 32;
  };

  resolve = {
    accents ? seed.accents,
    flavors ? seed.flavors,
    size ? seed.size,
    pkgs,
  }: {
    cursors = mkCursors {inherit accents flavors size pkgs;};
    themes = mkThemes {inherit accents flavors pkgs;};
    accent = accents.check accents;
    flavor = flavors.check flavors;
  };

  # Accent registry
  data = {
    accents = let
      registry = _.styles.queries.accents.all;
      names = attrNames registry;
      aliases =
        foldl' (
          acc: name:
            acc
            // listToAttrs (map (alias: {
                name = alias;
                value = name;
              })
              (registry.${name}.aliases or []))
        ) {}
        names;
      check = input: let
        fn = {
          name = "accents.check";
          context = "validating catppuccin accent";
        };
        value = toLowerCase input;
        normalized = aliases.${value} or value;
      in
        assert withContext {
          inherit (fn) name context;
          assertion = isIn normalized names;
          message = "invalid accent `${input}` - valid: ${toString names}";
        }; normalized;
    in {inherit registry names aliases check;};

    # Flavor registry

    flavors = let
      registry = _.styles.queries.flavors.all;
      names = attrNames registry;
      aliases =
        foldl' (
          acc: name:
            acc
            // listToAttrs (map (alias: {
                name = alias;
                value = name;
              })
              (registry.${name}.aliases or []))
        ) {}
        names;
      check = input: let
        fn = {
          name = "flavors.check";
          context = "validating catppuccin flavor";
        };
        value = toLowerCase input;
        normalized = aliases.${value} or value;
      in
        assert withContext {
          inherit (fn) name context;
          assertion = isIn normalized names;
          message = "invalid flavor `${input}` - valid: ${toString names}";
        }; normalized;
      light = filter (name: registry.${name}.polarity == "light") names;
      dark = filter (name: registry.${name}.polarity == "dark") names;
    in {inherit registry names aliases check light dark;};
  };
  # Cursor builder
  # Returns { light, dark } each { name, package, size }

  mkCursor = {
    accent ? seed.accent,
    flavor ? seed.flavor,
    size ? seed.size,
    pkgs,
  }: let
    fn = {
      name = "catppuccin.cursor";
      context = "building catppuccin cursor";
    };
    accentName = data.accents.check accent;
    darkFlavor = data.flavors.check flavor;
    lightFlavor = head data.flavors.light;
    mkName = flavorName: "catppuccin-${flavorName}-${accentName}-cursors";
    mkPkg = flavorName:
      getPackage {
        inherit pkgs;
        target = "catppuccin-cursors.${flavorName}${toPascalCase accentName}";
      };
  in
    assert withContext {
      inherit (fn) name context;
      assertion = data.flavors.light != [];
      message = "no light flavors found in registry";
    }; {
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

  # Cursors (list form)

  mkCursors = args: let
    result = mkCursor args;
  in [result.light result.dark];
  # Theme variant builder
  # Takes polarity, returns { name, scheme, package, polarity }

  mkTheme = {
    pkgs,
    polarity ? "dark",
    accent ? defaults.accent.${polarity},
    flavor ? defaults.flavor.${polarity},
  }: let
    fn = {
      name = "mkCatppuccinTheme";
      context = "building catppuccin theme variant";
    };

    accent' = accents.check (
      if isAttrs accent
      then accent.${polarity}
      else accent
    );

    flavor' = flavors.check (
      if isAttrs flavor
      then flavor.${polarity}
      else flavor
    );

    key = "catppuccin-${flavor'}";
    entry = assert withContext {
      inherit (fn) name context;
      assertion = _.styles.queries.themes.all ? ${key};
      message = "no theme entry for flavor `${flavorName}` (looked up `${key}`)";
    };
      _.styles.queries.themes.all.${key};
  in {
    name = entry.name;
    scheme = entry.scheme;
    polarity = entry.polarity;
    package = getPackage {
      inherit pkgs;
      target = entry.package;
    };
    flavor = flavor';
    accent = accent';
  };

  # Themes (both polarities)
  # Returns { light, dark } each { name, scheme, package, polarity }

  mkThemes = {
    accent ? data.accent,
    flavor ? data.flavor,
    pkgs,
  }: let
    mk = polarity: mkTheme {inherit accent flavor pkgs polarity;};
  in {
    light = mk "light";
    dark = mk "dark";
  };
in
  meta.exports.local
  // {
    __docs = meta.doc;
    __rootAliases = meta.exports.alias;
  }
