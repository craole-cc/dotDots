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
  inherit (_.strings.construction) concat;
  inherit (_.strings.transformation) toLowerCase toTitleCase;
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
            }) (registry.${name}.aliases or []))
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
            }) (registry.${name}.aliases or []))
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

  /**
    Normalize a polarity-aware input to a single string for the given polarity.

    Accepts four input shapes:
    - `null`     → falls back to `seed.${group}.${polarity}`
    - `string`   → used as-is for both polarities
    - `list`     → must have exactly 2 elements `[ darkVal lightVal ]`
    - `attrset`  → must have a `${polarity}` key

    # Type
  ```nix
    normalize :: { group :: string, value :: null | string | [ string string ] | { light :: string, dark :: string }, polarity :: string } -> string
  ```

    # Examples
  ```nix
    normalize { group = "accent"; value = null;                          polarity = "dark";  }  # "sky"
    normalize { group = "flavor"; value = "mocha";                       polarity = "light"; }  # "mocha"
    normalize { group = "accent"; value = [ "red" "blue" ];              polarity = "dark";  }  # "red"
    normalize { group = "flavor"; value = { light = "latte"; dark = "frappe"; }; polarity = "light"; }  # "latte"
  ```
  */
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
        message = "list input must have exactly 2 elements [darkVal lightVal], got ${toString (length value)}";
      };
        if polarity == "dark"
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

  /**
    Build a single cursor variant for the given polarity.

    Accent and flavor are resolved per-polarity via `normalize`, so callers
    may pass a string (same for both), a list `[ darkVal lightVal ]`, or an
    attrset `{ light, dark }`.

    # Type
  ```nix
    mkCursor :: { pkgs :: pkgs, polarity :: string?, accent :: null | string | [ string string ] | { light :: string, dark :: string }?, flavor :: null | string | [ string string ] | { light :: string, dark :: string }?, size :: int? } -> { name :: string, package :: derivation, size :: int }
  ```

    # Examples
  ```nix
    mkCursor { inherit pkgs; }
    mkCursor { inherit pkgs; polarity = "light"; accent = "pink"; }
    mkCursor { inherit pkgs; polarity = "dark";  accent = "sky";  flavor = "mocha"; size = 24; }
  ```
  */
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
    accent' = data.accents.check (normalize {
      inherit polarity;
      group = "accent";
      value = accent;
    });
    flavor' = data.flavors.check (normalize {
      inherit polarity;
      group = "flavor";
      value = flavor;
    });
    target = "catppuccin-cursors.${flavor'}${toTitleCase accent'}";
  in
    assert withContext {
      inherit (fn) name context;
      assertion = data.flavors.light != [];
      message = "no light flavors found in registry";
    }; {
      name = "catppuccin-${flavor'}-${accent'}-cursors";
      package = getPackage {
        pkgs = pkgs.catppuccin-cursors;
        target = concat "" [flavor' (toTitleCase accent)];
      };
      inherit size target;
    };

  /**
    Build cursor variants for both polarities.

    Calls `mkCursor` twice with polarity-resolved accent and flavor values.
    Returns `{ light, dark }` each containing `{ name, package, size }`.

    # Type
  ```nix
    mkCursors :: { pkgs :: pkgs, accent :: null | string | [ string string ] | { light :: string, dark :: string }?, flavor :: null | string | [ string string ] | { light :: string, dark :: string }?, size :: int? } -> { light :: { name :: string, package :: derivation, size :: int }, dark :: { name :: string, package :: derivation, size :: int } }
  ```

    # Examples
  ```nix
    mkCursors { inherit pkgs; }
    mkCursors { inherit pkgs; accent = "pink"; }
    mkCursors { inherit pkgs; accent = [ "red" "blue" ]; flavor = { light = "latte"; dark = "mocha"; }; }
  ```
  */
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

  /**
    Build a single theme variant for the given polarity.

    Accent and flavor are resolved per-polarity via `normalize`. Returns a
    single attrset with the resolved theme name, scheme, package, flavor,
    and accent for that polarity.

    # Type
  ```nix
    mkTheme :: { pkgs :: pkgs, polarity :: string?, accent :: null | string | [ string string ] | { light :: string, dark :: string }?, flavor :: null | string | [ string string ] | { light :: string, dark :: string }? } -> { name :: string, scheme :: string, package :: derivation, flavor :: string, accent :: string }
  ```

    # Examples
  ```nix
    mkTheme { inherit pkgs; }
    mkTheme { inherit pkgs; polarity = "light"; }
    mkTheme { inherit pkgs; polarity = "dark"; accent = "sky"; flavor = "mocha"; }
  ```
  */
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
      group = "accent";
      value = accent;
    };
    flavor' = normalize {
      inherit polarity;
      group = "flavor";
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

  /**
    Build theme variants for both polarities.

    Calls `mkTheme` twice with polarity-resolved accent and flavor values.
    Returns `{ light, dark }` each containing `{ name, scheme, package, flavor, accent }`.

    # Type
  ```nix
    mkThemes :: { pkgs :: pkgs, accent :: null | string | [ string string ] | { light :: string, dark :: string }?, flavor :: null | string | [ string string ] | { light :: string, dark :: string }? } -> { light :: { name :: string, scheme :: string, package :: derivation, flavor :: string, accent :: string }, dark :: { name :: string, scheme :: string, package :: derivation, flavor :: string, accent :: string } }
  ```

    # Examples
  ```nix
    mkThemes { inherit pkgs; }
    mkThemes { inherit pkgs; accent = [ "red" "blue" ]; }
    mkThemes { inherit pkgs; accent = [ "red" "blue" ]; flavor = { light = "latte"; dark = "mocha"; }; }
  ```
  */
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

  /**
    Resolve a complete Catppuccin style set for both polarities.

    High-level entry point combining cursors and themes. Returns a single
    attrset with `cursors` and `themes`, each containing `{ light, dark }`.

    # Type
  ```nix
    resolve :: { pkgs :: pkgs, accent :: null | string | [ string string ] | { light :: string, dark :: string }?, flavor :: null | string | [ string string ] | { light :: string, dark :: string }?, size :: int? } -> { cursors :: { light :: { name :: string, package :: derivation, size :: int }, dark :: { ... } }, themes :: { light :: { name :: string, scheme :: string, package :: derivation, flavor :: string, accent :: string }, dark :: { ... } } }
  ```

    # Examples
  ```nix
    resolve { inherit pkgs; }
    resolve { inherit pkgs; accent = "pink"; flavor = "mocha"; }
    resolve { inherit pkgs; accent = { light = "sapphire"; dark = "sky"; }; flavor = [ "latte" "frappe" ]; size = 24; }
  ```
  */
  resolve = {
    accent ? null,
    flavor ? null,
    size ? null,
    pkgs,
  }: let
    size' = optionalAttrs (size != null) {inherit size;};
    flavor' = optionalAttrs (flavor != null) {inherit flavor;};
    accent' = optionalAttrs (accent != null) {inherit accent;};
    common = {inherit pkgs;} // accent' // flavor';
  in {
    cursors = mkCursors (common // size');
    themes = mkThemes common;
  };
in
  meta.exports.local
  // {
    __docs = meta.doc;
    __rootAliases = meta.exports.alias;
  }
