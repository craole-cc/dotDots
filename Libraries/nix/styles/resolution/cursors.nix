{_, ...}: let
  meta = let
    doc = ''
      Cursor resolution (Layer 3).

      Builds cursor outputs as either one polarity (`mkOne`) or both polarities
      (`mkPair`). Empty cursor input falls back to generated Catppuccin cursors.
      Registry entries support normalized alias lookup.

      Depends on: styles.registry, styles.resolution.catppuccin,
      attrsets.resolution, strings.transformation.
    '';
    exports = {
      local = {
        inherit data mkOne mkPair;
        inherit (data) registry;
      };
      alias = {
        mkCursor = mkOne;
        mkCursors = mkPair;
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
  inherit (_.strings.transformation) toLowerCase;
  inherit (_.types.access) typeOf;
  inherit (_.types.predicates) isAttrs isList isString;
  inherit (_.styles.registry.groups.byCategory) cursors;
  mkCatppuccin = _.styles.resolution.catppuccin.cursors.mkOne;

  data = let
    raw = cursors;

    seed = {
      size = 24;
    };

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

    registry = {
      cursors = mkRegistry {
        group = "cursor";
        registry = raw;
      };
    };

    selectByPolarity = {
      value,
      polarity,
    }: let
      fn = {
        name = "cursors.selectByPolarity";
        context = "selecting ${polarity} cursor input";
      };
      isConcreteCursor = isAttrs value && ((hasAttr "package" value) || (hasAttr "name" value));
      isPolarizedCursor = isAttrs value && !isConcreteCursor;
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
      else if isConcreteCursor
      then value
      else if isPolarizedCursor
      then
        assert withContext {
          inherit (fn) name context;
          assertion = hasAttr polarity value;
          message = "cursor attrset input is missing `${polarity}` key";
        };
          getAttr polarity value
      else
        assert withContext {
          inherit (fn) name context;
          assertion = false;
          message = "expected null, string, list, or attrset, got `${typeOf value}`";
        }; null;

    normalize = {
      value,
      polarity,
    }: let
      selected = selectByPolarity {inherit value polarity;};
    in
      if isString selected
      then registry.cursors.lookup selected
      else selected;
  in {
    inherit raw seed registry normalize;
  };

  inherit (data) seed registry normalize;

  resolveEntry = {
    entry,
    polarity,
    size,
    pkgs,
  }: let
    fn = {
      name = "cursors.resolveEntry";
      context = "resolving cursor entry for ${polarity}";
    };

    cursorName =
      if isAttrs (entry.polarity or null)
      then
        assert withContext {
          inherit (fn) name context;
          assertion = hasAttr polarity entry.polarity;
          message = "polarity-aware entry missing `${polarity}` key";
        };
          entry.polarity.${polarity}.name
      else
        assert withContext {
          inherit (fn) name context;
          assertion = hasAttr "name" entry;
          message = "cursor entry has no `name` and polarity is not an attrset";
        };
          entry.name;
  in {
    name = cursorName;
    package = getPackage {
      inherit pkgs;
      target = entry.package;
    };
    inherit size;
  };

  mkOne = {
    pkgs,
    polarity ? "dark",
    cursor ? null,
    accent ? null,
    flavor ? null,
    size ? seed.size,
  }: let
    fn = {
      name = "cursors.mkOne";
      context = "building cursor for ${polarity}";
    };
    entry =
      if isEmpty cursor
      then null
      else
        normalize {
          inherit polarity;
          value = cursor;
        };
  in
    if entry == null
    then
      mkCatppuccin {
        inherit pkgs polarity accent flavor size;
      }
    else if isAttrs entry && hasAttr "package" entry && hasAttr "name" entry
    then
      if entry.generated or false
      then
        mkCatppuccin {
          inherit pkgs polarity accent flavor size;
        }
      else
        resolveEntry {
          inherit entry polarity size pkgs;
        }
    else if isAttrs entry && hasAttr "package" entry
    then
      assert withContext {
        inherit (fn) name context;
        assertion = hasAttr "name" entry;
        message = "cursor attrset has `package` but no `name`";
      }; null
    else
      assert withContext {
        inherit (fn) name context;
        assertion = false;
        message = "normalized cursor entry is invalid";
      }; null;

  mkPair = {pkgs, ...} @ args: {
    light = mkOne (args // {polarity = "light";});
    dark = mkOne (args // {polarity = "dark";});
  };
in
  meta.exports.local
  // {
    __docs = meta.doc;
    __rootAliases = meta.exports.alias;
  }
