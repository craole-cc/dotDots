{_, ...}: let
  meta = let
    doc = ''
      Cursor resolution (Layer 3).

      Builds cursor outputs as either one polarity (`mkOne`) or both polarities
      (`mkPair`). Empty cursor input falls back to generated Catppuccin cursors.
      Registry entries support normalized alias lookup. Family entries resolve
      to the closest matching cursor in the same family for the requested
      polarity.

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
  inherit (_.lists.selection) filter;
  inherit (_.strings.transformation) toLowerCase;
  inherit (_.types.access) typeOf;
  inherit (_.types.predicates) isAttrs isFunction isList isString;
  inherit (_.styles.registry.groups.byCategory) cursors;
  mkCatppuccin = _.styles.catppuccin.cursors.mkOne;

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
        name = "cursors.selectByPolarity";
        context = "selecting ${polarity} cursor input";
      };

      isConcreteCursor =
        isAttrs value && ((hasAttr "package" value) || (hasAttr "name" value));

      isPolarizedCursor =
        isAttrs value && !isConcreteCursor;
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
  };

  data = let
    raw = cursors;

    seed = {
      size = 24;
    };

    registry = {
      cursors = mkRegistry {
        group = "cursor";
        registry = raw;
      };
    };

    families = let
      byFamily = family:
        filter
        (name: raw.${name}.family == family)
        registry.cursors.names;
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
      then registry.cursors.lookup selected
      else selected;
  in {
    inherit raw seed registry families normalize;
  };

  inherit (data) raw seed registry families normalize;

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
    else if isAttrs entry && (entry.generated or false)
    then
      mkCatppuccin {
        inherit pkgs polarity accent flavor size;
      }
    else if isAttrs entry && (entry.family or null) == "catppuccin"
    then
      mkCatppuccin {
        inherit pkgs polarity accent flavor size;
      }
    else if isAttrs entry && hasAttr "family" entry
    then let
      familyCandidates =
        filter
        (name: (raw.${name}.family or null) == entry.family)
        registry.cursors.names;

      samePolarity =
        filter
        (
          name: let
            candidate = raw.${name};
          in
            if isAttrs (candidate.polarity or null)
            then hasAttr polarity candidate.polarity
            else (candidate.polarity or null) == polarity
        )
        familyCandidates;

      familyEntry =
        if samePolarity == []
        then null
        else registry.cursors.lookup (elemAt samePolarity 0);
    in
      if familyEntry == null
      then
        mkCatppuccin {
          inherit pkgs polarity accent flavor size;
        }
      else if (familyEntry.family or null) == "catppuccin"
      then
        mkCatppuccin {
          inherit pkgs polarity accent flavor size;
        }
      else if isAttrs (familyEntry.polarity or null)
      then let
        resolved = assert withContext {
          inherit (fn) name context;
          assertion = hasAttr polarity familyEntry.polarity;
          message = "polarity-aware cursor entry missing `${polarity}` key";
        };
          familyEntry.polarity.${polarity};
      in
        assert withContext {
          inherit (fn) name context;
          assertion = hasAttr "name" resolved;
          message = "resolved polarity cursor entry has no `name`";
        }; {
          name = resolved.name;
          package = getPackage {
            inherit pkgs;
            target = familyEntry.package;
          };
          inherit size;
        }
      else if hasAttr "package" familyEntry && hasAttr "name" familyEntry
      then {
        inherit (familyEntry) name;
        package = getPackage {
          inherit pkgs;
          target = familyEntry.package;
        };
        inherit size;
      }
      else
        assert withContext {
          inherit (fn) name context;
          assertion = false;
          message = "resolved family cursor entry is invalid";
        }; null
    else if isAttrs entry && hasAttr "package" entry && isAttrs (entry.polarity or null)
    then let
      resolved = assert withContext {
        inherit (fn) name context;
        assertion = hasAttr polarity entry.polarity;
        message = "polarity-aware cursor entry missing `${polarity}` key";
      };
        entry.polarity.${polarity};
    in
      assert withContext {
        inherit (fn) name context;
        assertion = hasAttr "name" resolved;
        message = "resolved polarity cursor entry has no `name`";
      }; {
        name = resolved.name;
        package = getPackage {
          inherit pkgs;
          target = entry.package;
        };
        inherit size;
      }
    else if isAttrs entry && hasAttr "package" entry && hasAttr "name" entry
    then {
      inherit (entry) name;
      package = getPackage {
        inherit pkgs;
        target = entry.package;
      };
      inherit size;
    }
    else if isAttrs entry && hasAttr "package" entry
    then
      assert withContext {
        inherit (fn) name context;
        assertion = false;
        message = "cursor entry has `package` but neither top-level `name` nor polarity-aware `name`";
      }; null
    else
      assert withContext {
        inherit (fn) name context;
        assertion = false;
        message = "normalized cursor entry is invalid";
      }; null;

  mkPair = mkPolarity.pair {
    fn = mkOne;
    args = ["pkgs" "cursor" "accent" "flavor" "size"];
  };
in
  meta.exports.local
  // {
    __docs = meta.doc;
    __rootAliases = meta.exports.alias;
  }
