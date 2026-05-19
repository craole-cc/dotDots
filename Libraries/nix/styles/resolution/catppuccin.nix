{_, ...}: let
  meta = let
    doc = ''
      Catppuccin resolution (Layer 3).

      Registry-driven accent/flavor validation plus theme and cursor builders
      for the Catppuccin family. Theme and cursor builders are grouped into
      sub-namespaces with mkOne/mkPair APIs.

      Depends on: styles.filters, attrsets.resolution, strings.transformation.
    '';
    exports = {
      local = {inherit data normalize themes cursors mkFamily;};
      alias = {
        mkCatppuccinTheme = themes.mkOne;
        mkCatppuccinThemes = themes.mkPair;
        mkCatppuccinCursor = cursors.mkOne;
        mkCatppuccinCursors = cursors.mkPair;
        mkCatppuccin = mkFamily;
      };
    };
  in {
    inherit doc exports;
  };

  inherit (_.attrsets.access) attrNames getAttr;
  inherit (_.attrsets.construction) listToAttrs optionalAttrs;
  inherit (_.attrsets.predicates) hasAttr;
  inherit (_.attrsets.resolution) getPackage;
  inherit (_.content.emptiness) isEmpty isNotEmpty;
  inherit (_.debug.assertions) withContext;
  inherit (_.lists.access) elemAt length;
  inherit (_.lists.aggregation) foldl';
  inherit (_.lists.predicates) isIn;
  inherit (_.lists.selection) filter;
  inherit (_.strings.construction) concat;
  inherit (_.strings.transformation) toLowerCase toTitleCase;
  inherit (_.types.access) typeOf;
  inherit (_.types.predicates) isAttrs isFunction isList isString;
  inherit (_.styles.registry.groups.byFamily) catppuccin;

  mkRegistry = {
    group,
    registry,
  }: let
    names = attrNames registry;
    aliases =
      foldl'
      (
        acc: value:
          acc
          // {${toLowerCase value} = value;}
          // listToAttrs (
            map
            (name: {inherit name value;})
            (
              map
              toLowerCase
              (registry.${value}.aliases or [])
            )
          )
      )
      {}
      names;

    has = input: let
      value = toLowerCase input;
    in
      hasAttr value aliases || isIn value names;

    lookup = input: let
      fn = {
        name = "${group}.lookup";
        context = "looking up catppuccin ${group}";
      };
      value = toLowerCase input;
      resolved = aliases.${value} or value;
    in
      assert withContext {
        inherit (fn) name context;
        assertion = isIn resolved names;
        message = "invalid ${group} `${input}` - valid: ${toString names}";
      }; resolved;
  in {
    inherit registry names aliases has lookup;
  };

  data = let
    raw = catppuccin;

    seed = {
      accent = {
        dark = "rosewater";
        light = "sapphire";
      };
      flavor = {
        dark = "frappe";
        light = "latte";
      };
      size = 32;
    };

    registry = {
      accents = mkRegistry {
        group = "accent";
        registry = raw.accents;
      };

      flavors = let
        base = mkRegistry {
          group = "flavor";
          registry = raw.flavors;
        };
        byPolarity = polarity:
          filter
          (name: raw.flavors.${name}.polarity == polarity)
          base.names;
      in
        base
        // {
          dark = byPolarity "dark";
          light = byPolarity "light";
        };
    };
  in {inherit raw seed registry;};
  inherit (data) raw seed registry;

  mkPolarity = {
    pair = input: let
      spec =
        if isFunction input
        then {fn = input;}
        else input;

      fn = assert withContext {
        name = "mkPolarity.pair";
        context = "building polarity pair wrapper";
        assertion = isAttrs spec && hasAttr "fn" spec && isFunction spec.fn;
        message = "expected a function or an attrset with `fn` as a function";
      };
        spec.fn;
    in {
      light = args: fn (args // {polarity = "light";});
      dark = args: fn (args // {polarity = "dark";});
    };

    selection = {
      group,
      value,
      polarity,
    }: let
      fn = {
        name = "selectByPolarity";
        context = "selecting ${polarity} ${group} input for catppuccin";
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
          assertion = hasAttr polarity value;
          message = "attrset input is missing `${polarity}` key";
        };
          getAttr polarity value
      else
        assert withContext {
          inherit (fn) name context;
          assertion = false;
          message = "expected null, string, list, or attrset, got `${typeOf value}`";
        }; null;
  };

  classify = value:
    if !isString value
    then null
    else
      with registry;
        if accents.has value
        then "accent"
        else if flavors.has value
        then "flavor"
        else null;

  normalize = {
    group,
    value,
    polarity,
  }: let
    fn = {
      name = "normalize";
      context = "normalizing ${polarity} ${group} for catppuccin";
    };
    selected = mkPolarity.selection {inherit group value polarity;};
  in
    assert withContext {
      inherit (fn) name context;
      assertion = isIn group ["accent" "flavor"];
      message = "unsupported group `${group}`";
    };
    with registry;
      if group == "accent"
      then accents.lookup selected
      else flavors.lookup selected;

  mkOverride = {
    input,
    group,
    polarity,
    argument,
    context,
  }: let
    value =
      if isEmpty input
      then null
      else
        mkPolarity.selection {
          inherit group polarity;
          value = input;
        };
    kind = classify value;
  in
    if isEmpty input
    then {}
    else if kind == "accent"
    then {accent = value;}
    else if kind == "flavor"
    then {flavor = value;}
    else
      assert withContext {
        name = "catppuccin.mkOverride";
        inherit context;
        assertion = false;
        message = "unsupported `${argument}` `${toString input}` - expected a catppuccin accent, flavor, or empty value";
      }; null;

  cursors = let
    resolve = {
      pkgs,
      polarity,
      size,
      accent,
      flavor,
    }: let
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
      target = concat "" [flavor' (toTitleCase accent')];
    in {
      name = "catppuccin-${flavor'}-${accent'}-cursors";
      package = getPackage {
        pkgs = pkgs.catppuccin-cursors;
        inherit target;
      };
      inherit size target;
    };

    mkOne = {
      pkgs,
      polarity ? "dark",
      cursor ? null,
      accent ? seed.accent.${polarity},
      flavor ? seed.flavor.${polarity},
      size ? seed.size,
    }: let
      base = {inherit pkgs polarity size accent flavor;};
      override = mkOverride {
        input = cursor;
        group = "accent";
        inherit polarity;
        argument = "cursor";
        context = "building catppuccin cursor variant";
      };
    in
      resolve (base // override);

    mkPair = mkPolarity.pair mkOne;
  in {
    inherit mkOne mkPair;
  };

  themes = let
    resolve = {
      pkgs,
      polarity,
      accent,
      flavor,
    }: let
      fn = {
        name = "catppuccin.themes.resolve";
        context = "resolving catppuccin theme variant";
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
      entry = assert withContext {
        inherit (fn) name context;
        assertion = hasAttr key raw.themes;
        message = "no theme entry for flavor `${flavor'}` (looked up `${key}`)";
      };
        getAttr key raw.themes;
    in {
      inherit (entry) name scheme;
      package = getPackage {
        inherit pkgs;
        target = entry.package;
      };
      flavor = flavor';
      accent = accent';
    };

    mkOne = {
      pkgs,
      polarity ? "dark",
      theme ? null,
      accent ? seed.accent.${polarity},
      flavor ? seed.flavor.${polarity},
    }: let
      base = {inherit pkgs polarity accent flavor;};
      override = mkOverride {
        input = theme;
        group = "flavor";
        inherit polarity;
        argument = "theme";
        context = "building catppuccin theme variant";
      };
    in
      resolve (base // override);

    mkPair = mkPolarity.pair mkOne;
  in {inherit mkOne mkPair;};

  mkFamily = {
    accent ? seed.accent,
    flavor ? seed.flavor,
    size ? seed.size,
    pkgs,
  }: let
    size' = optionalAttrs (isNotEmpty size) {inherit size;};
    flavor' = optionalAttrs (isNotEmpty flavor) {inherit flavor;};
    accent' = optionalAttrs (isNotEmpty accent) {inherit accent;};
    common = {inherit pkgs;} // accent' // flavor';
  in {
    cursors = cursors.mkPair (common // size');
    themes = themes.mkPair common;
  };
in
  meta.exports.local
  // {
    __docs = meta.doc;
    __rootAliases = meta.exports.alias;
  }
