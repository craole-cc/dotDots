{_, ...}: let
  meta = let
    doc = ''
      Icon resolution (Layer 3).

      Builds icon outputs as either one polarity (`mkOne`) or both polarities
      (`mkPair`). Empty icon input falls back to Candy Icons. Registry entries
      support normalized alias lookup. Family entries resolve to the closest
      matching icon in the same family for the requested polarity.

      Depends on: styles.registry, attrsets.resolution, strings.transformation.
    '';
    exports = {
      local = {
        inherit data mkOne mkPair;
        inherit (data) registry;
      };
      alias = {
        mkIcon = mkOne;
        mkIcons = mkPair;
      };
    };
  in {
    inherit doc exports;
  };

  inherit (_.attrsets.access) attrNames getAttr;
  inherit (_.attrsets.construction) listToAttrs;
  inherit (_.attrsets.predicates) hasAttr;
  inherit (_.attrsets.resolution) getPackage;
  inherit (_.content.emptiness) isEmpty;
  inherit (_.debug.assertions) withContext;
  inherit (_.lists.access) elemAt length;
  inherit (_.lists.aggregation) foldl';
  inherit (_.lists.predicates) isIn;
  inherit (_.lists.selection) filter;
  inherit (_.strings.transformation) toLowerCase;
  inherit (_.types.access) typeOf;
  inherit (_.types.predicates) isAttrs isFunction isList isString;
  inherit (_.styles.registry.groups.byCategory) icons;

  data = let
    raw = icons;

    seed = {icon = "candy-icons";};

    registry = {
      icons = mkRegistry {
        group = "icon";
        registry = raw;
      };
    };

    families = let
      byFamily = family:
        filter
        (name: raw.${name}.family == family)
        registry.icons.names;
    in {
      inherit byFamily;
    };
  in {inherit raw seed registry families;};
  inherit (data) raw seed registry;

  normalize = {
    value,
    polarity,
  }: let
    selected =
      if isEmpty value
      then seed.icon
      else mkPolarity.selection {inherit value polarity;};
  in
    if isString selected
    then registry.icons.lookup selected
    else selected;

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
  in {inherit registry names aliases lookup;};

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
        name = "icons.selectByPolarity";
        context = "selecting ${polarity} icon input";
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
          message = "icon attrset input is missing `${polarity}` key";
        };
          getAttr polarity value
      else
        assert withContext {
          inherit (fn) name context;
          assertion = false;
          message = "expected null, string, list, or attrset, got `${typeOf value}`";
        }; null;
  };

  mkOne = {
    pkgs,
    polarity ? "dark",
    icon ? null,
  }: let
    fn = {
      name = "icons.mkOne";
      context = "building icon theme for ${polarity}";
    };

    fallback = registry.icons.lookup seed.icon;

    entry = normalize {
      inherit polarity;
      value = icon;
    };
  in
    if isAttrs entry && hasAttr "family" entry
    then let
      familyCandidates =
        filter
        (name: (raw.${name}.family or null) == entry.family)
        registry.icons.names;

      samePolarity =
        filter
        (
          name: let
            candidate = raw.${name};
          in
            if isAttrs (candidate.polarity or null)
            then hasAttr polarity candidate.polarity
            else true
        )
        familyCandidates;

      familyEntry =
        if samePolarity == []
        then null
        else registry.icons.lookup (elemAt samePolarity 0);

      resolved =
        if familyEntry == null
        then fallback
        else familyEntry;
    in
      if isAttrs (resolved.polarity or null)
      then let
        variant = assert withContext {
          inherit (fn) name context;
          assertion = hasAttr polarity resolved.polarity;
          message = "polarity-aware icon entry missing `${polarity}` key";
        };
          resolved.polarity.${polarity};
      in
        assert withContext {
          inherit (fn) name context;
          assertion = hasAttr "name" variant;
          message = "resolved polarity icon entry has no `name`";
        }; {
          name = variant.name;
          package = getPackage {
            inherit pkgs;
            target = resolved.package;
          };
        }
      else if hasAttr "name" resolved && hasAttr "package" resolved
      then {
        inherit (resolved) name;
        package = getPackage {
          inherit pkgs;
          target = resolved.package;
        };
      }
      else
        assert withContext {
          inherit (fn) name context;
          assertion = false;
          message = "resolved icon entry is invalid";
        }; null
    else
      assert withContext {
        inherit (fn) name context;
        assertion = false;
        message = "normalized icon entry is invalid";
      }; null;

  mkPair = mkPolarity.pair {
    fn = mkOne;
    args = ["pkgs" "icon"];
  };
in
  meta.exports.local
  // {
    __docs = meta.doc;
    __rootAliases = meta.exports.alias;
  }
