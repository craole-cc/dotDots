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
  inherit (_.attrsets.construction) listToAttrs optionalAttrs;
  inherit (_.attrsets.resolution) getPackage;
  inherit (_.content.emptiness) isEmpty isNotEmpty;
  inherit (_.lists.access) elemAt head length;
  inherit (_.lists.aggregation) foldl';
  inherit (_.lists.predicates) isIn;
  inherit (_.lists.selection) filter;
  inherit (_.strings.transformation) toLowerCase toPascalCase;
  inherit (_.debug.assertions) withContext;
  inherit (_.types.predicates) isAttrs isList isString;
  inherit (_.styles.registry.groups.byFamily.catppuccin) accents cursors flavors themes;

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

  # Accent registry
  data = {
    themes = {registry = themes;};
    cursors = {registry = cursors;};
    accents = let
      registry = accents;
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
      registry = flavors;
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

  # Cursors (both polarities)
  # Returns { light, dark } each { name, package, size }
  # accent/flavor accept: string | [ lightVal darkVal ] | { light, dark }

  mkCursors = {
    pkgs,
    accent ? null,
    flavor ? null,
    size ? seed.size,
  }: let
    mk = polarity:
      mkCursor {
        inherit pkgs polarity size;
        accent = normalize {
          inherit polarity;
          group = "accent";
          value = accent;
        };
        flavor = normalize {
          inherit polarity;
          group = "flavor";
          value = flavor;
        };
      };
  in {
    light = mk "light";
    dark = mk "dark";
  };

  # Cursor variant builder
  # Takes polarity, returns { name, package, size }

  mkCursor = {
    pkgs,
    polarity ? "dark",
    accent ? seed.accent.${polarity},
    flavor ? seed.flavor.${polarity},
    size ? seed.size,
  }: let
    fn = {
      name = "mkCatppuccinCursor";
      context = "building catppuccin cursor variant";
    };
    accentName = data.accents.check (normalize {
      inherit polarity;
      group = "accent";
      value = accent;
    });
    flavorName = data.flavors.check (normalize {
      inherit polarity;
      group = "flavor";
      value = flavor;
    });
  in
    assert withContext {
      inherit (fn) name context;
      assertion = data.flavors.light != [];
      message = "no light flavors found in registry";
    }; {
      name = "catppuccin-${flavorName}-${accentName}-cursors";
      package = getPackage {
        inherit pkgs;
        target = "catppuccin-cursors.${flavorName}${toPascalCase accentName}";
      };
      inherit size;
    };

  # Themes (both polarities)
  # Returns { light, dark } each { name, scheme, package, polarity, flavor, accent }
  # accent/flavor accept: string | [ lightVal darkVal ] | { light, dark }
  mkThemes = {
    pkgs,
    accent ? null,
    flavor ? null,
  }: let
    mk = polarity:
      mkTheme {
        inherit pkgs polarity;
        accent = normalize {
          inherit polarity;
          group = "accent";
          value = accent;
        };
        flavor = normalize {
          inherit polarity;
          group = "flavor";
          value = flavor;
        };
      };
  in {
    light = mk "light";
    dark = mk "dark";
  };

  # Theme variant builder
  # Takes polarity, returns { name, scheme, package, polarity }
  mkTheme = {
    pkgs,
    polarity ? "dark",
    accent ? seed.accent.${polarity},
    flavor ? seed.flavor.${polarity},
  }: let
    fn = {
      name = "mkCatppuccinTheme";
      context = "building catppuccin theme variant";
    };

    accent' = normalize {
      inherit polarity;
      group = "accents";
      value = accent;
    };

    flavor' = normalize {
      inherit polarity;
      group = "flavors";
      value = flavor;
    };

    key = "catppuccin-${flavor'}";
    theme = assert withContext {
      inherit (fn) name context;
      assertion = themes ? ${key};
      message = "no theme entry for flavor `${flavor'}` (looked up `${key}`)";
    };
      themes.${key};
  in {
    inherit (theme) name scheme;
    package = getPackage {
      inherit pkgs;
      target = theme.package;
    };
    flavor = flavor';
    accent = accent';
  };

  normalize = {
    group,
    value,
    polarity,
  }: let
    fn = {
      name = "normalize";
      context = "normalizing ${polarity} ${group} for catppuccin";
    };
  in
    if value == null
    then seed.${group}.${polarity}
    else if isString value
    then value
    else if isList value
    then
      assert withContext {
        inherit (fn) name context;
        assertion = length value == 2;
        message = "list input must have exactly 2 elements [lightVal darkVal], got ${
          toString (length value)
        }";
      };
        if polarity == "light"
        then elemAt value 0
        else elemAt value 1
    else if isAttrs value
    then
      assert withContext {
        inherit (fn) name context;
        assertion = value ? ${polarity};
        message = "attrset input is missing `${polarity}` key";
      };
        value.${polarity}
    else
      assert withContext {
        inherit (fn) name context;
        assertion = false;
        message = "expected null, string, list, or attrset, got `${toString value}`";
      }; null;

  resolve = {
    accents ? seed.accent,
    flavors ? seed.flavor,
    size ? seed.size,
    pkgs,
  }: {
    cursors = mkCursors {inherit accents flavors size pkgs;};
    themes = mkThemes {inherit accents flavors pkgs;};
    accent = accents.check accents;
    flavor = flavors.check flavors;
  };
in
  meta.exports.local
  // {
    __docs = meta.doc;
    __rootAliases = meta.exports.alias;
  }
