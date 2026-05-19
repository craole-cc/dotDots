{_, ...}: let
  meta = let
    doc = ''
      Theme resolution (Layer 3).

      Dispatches any theme input to { light, dark } each
      { name, scheme, package, polarity, flavor, accent }.
      Family entries resolve to the closest matching theme in the same family
      for the requested polarity. Catppuccin family entries delegate to the
      Catppuccin resolver.

      Depends on: styles.registry, styles.resolution.catppuccin, attrsets.resolution.
    '';
    exports = {
      local = {inherit data mkOne mkPair;};
      alias = {resolveTheme = mkOne;};
    };
  in {
    inherit doc exports;
  };

  inherit (_.attrsets.access) attrNames getAttr;
  inherit (_.attrsets.construction) listToAttrs;
  inherit (_.attrsets.predicates) hasAttr;
  inherit (_.attrsets.resolution) getPackage;
  inherit (_.content.emptiness) isEmpty isNotEmpty;
  inherit (_.debug.assertions) withContext;
  inherit (_.lists.access) elemAt length;
  inherit (_.lists.aggregation) foldl';
  inherit (_.lists.predicates) isIn;
  inherit (_.lists.selection) filter;
  inherit (_.strings.transformation) toLowerCase;
  inherit (_.types.access) typeOf;
  inherit (_.types.predicates) isAttrs isFunction isList isString;
  inherit (_.styles.registry.queries.themes) all;

  mkCatppuccin = _.styles.resolution.catppuccin.themes.mkOne;

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

    lookup = input: let
      fn = {
        name = "${group}.lookup";
        context = "looking up ${group}";
      };
      value = toLowerCase input;
      resolved = aliases.${value} or value;
    in
      assert withContext {
        inherit (fn) name context;
        assertion = isIn resolved names;
        message = "unknown ${group} `${input}` - valid: ${toString names}";
      };
        registry.${resolved};
  in {
    inherit registry names aliases lookup;
  };

  mkPolarity = {
    pair = input: let
      spec =
        if isFunction input
        then {
          fn = input;
          args = [];
        }
        else input;

      fn = assert withContext {
        name = "mkPolarity.pair";
        context = "building polarity pair wrapper";
        assertion =
          isAttrs spec
          && hasAttr "fn" spec
          && isFunction spec.fn
          && ((spec.args or []) == [] || isList (spec.args or []));
        message = "expected a function or an attrset with `fn` as a function and optional `args` as a list";
      };
        spec.fn;

      allowed = (spec.args or []) ++ ["polarity"];

      validate = args: let
        invalid =
          filter
          (name: !(isIn name allowed))
          (attrNames args);
      in
        assert withContext {
          name = "mkPolarity.pair";
          context = "validating polarity pair arguments";
          assertion = invalid == [];
          message = "unexpected arguments `${toString invalid}` - allowed: ${toString (spec.args or [])}";
        }; args;
    in
      args: let
        checked = validate args;
      in {
        light = fn (checked // {polarity = "light";});
        dark = fn (checked // {polarity = "dark";});
      };

    selection = {
      value,
      polarity,
    }: let
      fn = {
        name = "themes.selectByPolarity";
        context = "selecting ${polarity} theme input";
      };
    in
      if value == null
      then null
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
          message = "theme attrset input is missing `${polarity}` key";
        };
          value.${polarity}
      else
        assert withContext {
          inherit (fn) name context;
          assertion = false;
          message = "expected null, string, list, or attrset, got `${typeOf value}`";
        }; null;
  };

  data = let
    raw = all;

    registry = {
      themes = mkRegistry {
        group = "theme";
        registry = raw;
      };
    };

    families = let
      byFamily = family:
        filter
        (name: raw.${name}.family == family)
        registry.themes.names;
    in {
      inherit byFamily;
    };

    normalize = {
      value,
      polarity,
    }: let
      selected = mkPolarity.selection {inherit value polarity;};
    in
      if isString selected
      then registry.themes.lookup selected
      else selected;
  in {
    inherit raw registry families normalize;
  };

  inherit (data) raw registry families normalize;

  resolveFamily = {
    entry,
    polarity,
  }: let
    fn = {
      name = "themes.resolveFamily";
      context = "resolving theme family for ${polarity}";
    };

    family = entry.family or null;
    candidateNames =
      if isString family
      then families.byFamily family
      else [];

    candidate =
      if isEmpty candidateNames
      then null
      else let
        matches =
          filter
          (name: (raw.${name}.polarity or null) == polarity)
          candidateNames;
      in
        if isEmpty matches
        then null
        else registry.themes.lookup (elemAt matches 0);
  in
    if candidate == null
    then
      mkCatppuccin {
        inherit polarity;
        pkgs = entry.pkgs or null;
        accent = null;
        flavor = null;
      }
    else candidate;

  mkOne = {
    pkgs,
    polarity ? "dark",
    theme ? null,
    accent ? null,
    flavor ? null,
  }: let
    fn = {
      name = "themes.mkOne";
      context = "building theme for ${polarity}";
    };

    entry =
      if isEmpty theme
      then null
      else
        normalize {
          inherit polarity;
          value = theme;
        };
  in
    if entry == null
    then
      mkCatppuccin {
        inherit pkgs polarity accent flavor;
      }
    else if isAttrs entry && (entry.family or null) == "catppuccin"
    then
      mkCatppuccin {
        inherit pkgs polarity accent flavor;
      }
    else if isAttrs entry && hasAttr "name" entry && hasAttr "family" entry
    then let
      familyCandidates =
        filter
        (name: (raw.${name}.family or null) == entry.family)
        registry.themes.names;

      samePolarity =
        filter
        (name: (raw.${name}.polarity or null) == polarity)
        familyCandidates;

      familyEntry =
        if isEmpty samePolarity
        then null
        else registry.themes.lookup (elemAt samePolarity 0);
    in
      if familyEntry == null
      then
        mkCatppuccin {
          inherit pkgs polarity accent flavor;
        }
      else if (familyEntry.family or null) == "catppuccin"
      then
        mkCatppuccin {
          inherit pkgs polarity accent flavor;
        }
      else {
        inherit (familyEntry) name polarity;
        scheme = familyEntry.scheme or null;
        package =
          if isNotEmpty (familyEntry.package or null)
          then
            getPackage {
              inherit pkgs;
              target = familyEntry.package;
            }
          else null;
        flavor = familyEntry.flavor or null;
        accent = familyEntry.accent or null;
      }
    else if isAttrs entry && hasAttr "name" entry
    then {
      inherit (entry) name;
      polarity = entry.polarity or polarity;
      scheme = entry.scheme or null;
      package =
        if isNotEmpty (entry.package or null)
        then
          getPackage {
            inherit pkgs;
            target = entry.package;
          }
        else null;
      flavor = entry.flavor or null;
      accent = entry.accent or null;
    }
    else
      assert withContext {
        inherit (fn) name context;
        assertion = false;
        message = "normalized theme entry is invalid";
      }; null;

  mkPair = mkPolarity.pair {
    fn = mkOne;
    args = ["pkgs" "theme" "accent" "flavor"];
  };
in
  meta.exports.local
  // {
    __docs = meta.doc;
    __rootAliases = meta.exports.alias;
  }
