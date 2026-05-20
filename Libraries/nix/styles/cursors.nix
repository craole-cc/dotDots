{_, ...}: let
  meta = let
    doc = ''
      Cursor resolution (Layer 3).

      Builds cursor outputs as either one polarity (`mkOne`) or both polarities
      (`mkPair`). Empty cursor input falls back to generated Catppuccin cursors.
      Registry entries support normalized alias lookup. Family entries resolve
      to the closest matching cursor in the same family for the requested
      polarity.

      Depends on: styles.registry, styles.catppuccin, attrsets.resolution.
    '';
    alias = {
      mkCursor = mkOne;
      mkCursors = mkPair;
    };
    exports = {
      local = {inherit data mkOne mkPair;} // alias;
      inherit alias;
    };
  in {
    inherit doc exports;
  };

  inherit (_.attrsets.access) attrNames;
  inherit (_.attrsets.predicates) hasAttr;
  inherit (_.attrsets.resolution) getPackage;
  inherit (_.content.emptiness) isEmpty isNotEmpty;
  inherit (_.debug.assertions) withContext;
  inherit (_.lists.access) elemAt;
  inherit (_.lists.selection) filter;
  inherit (_.types.predicates) isAttrs;
  inherit (_.styles.registry) mkData mkPolarity;

  mkCatppuccin = _.styles.catppuccin.cursors.mkOne;

  data = mkData {
    domain = "cursors";
    seed = {size = 24;};
    groupBy = ["byFamily"];
  };

  inherit (data) seed normalize groups;
  inherit (data.resolved) lookup;

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
      context = "building cursor theme for ${polarity}";
    };

    entry = normalize {
      inherit polarity;
      value = cursor;
    };
  in
    if entry == null
    then
      mkCatppuccin {
        inherit pkgs polarity accent flavor size;
      }
    else if isAttrs entry && ((entry.generated or false) || (entry.family or null) == "catppuccin")
    then
      mkCatppuccin {
        inherit pkgs polarity accent flavor size;
      }
    else if isAttrs entry && hasAttr "family" entry
    then let
      candidates = groups.byFamily.${entry.family} or {};

      candidate = let
        samePolarity =
          filter
          (
            name: let
              item = candidates.${name};
            in
              if isAttrs (item.polarity or null)
              then hasAttr polarity item.polarity
              else (item.polarity or null) == polarity || (item.polarity or null) == null
          )
          (attrNames candidates);
      in
        if isNotEmpty samePolarity
        then lookup (elemAt samePolarity 0)
        else null;

      resolved =
        if candidate != null
        then candidate
        else null;
    in
      if resolved == null
      then
        mkCatppuccin {
          inherit pkgs polarity accent flavor size;
        }
      else if (resolved.family or null) == "catppuccin"
      then
        mkCatppuccin {
          inherit pkgs polarity accent flavor size;
        }
      else if isAttrs (resolved.polarity or null)
      then let
        variant = assert withContext {
          inherit (fn) name context;
          assertion = hasAttr polarity resolved.polarity;
          message = "polarity-aware cursor entry missing `${polarity}` key";
        };
          resolved.polarity.${polarity};
      in
        assert withContext {
          inherit (fn) name context;
          assertion = hasAttr "name" variant;
          message = "resolved polarity cursor entry has no `name`";
        }; {
          name = variant.name;
          package = getPackage {
            inherit pkgs;
            target = resolved.package;
          };
          inherit size;
        }
      else if hasAttr "name" resolved && hasAttr "package" resolved
      then {
        inherit (resolved) name;
        package = getPackage {
          inherit pkgs;
          target = resolved.package;
        };
        inherit size;
      }
      else
        assert withContext {
          inherit (fn) name context;
          assertion = false;
          message = "resolved cursor entry is invalid";
        }; null
    else if isAttrs entry && isAttrs (entry.polarity or null)
    then let
      variant = assert withContext {
        inherit (fn) name context;
        assertion = hasAttr polarity entry.polarity;
        message = "polarity-aware cursor entry missing `${polarity}` key";
      };
        entry.polarity.${polarity};
    in
      assert withContext {
        inherit (fn) name context;
        assertion = hasAttr "name" variant && hasAttr "package" entry;
        message = "resolved polarity cursor entry is invalid";
      }; {
        name = variant.name;
        package = getPackage {
          inherit pkgs;
          target = entry.package;
        };
        inherit size;
      }
    else if isAttrs entry && hasAttr "name" entry && hasAttr "package" entry
    then {
      inherit (entry) name;
      package = getPackage {
        inherit pkgs;
        target = entry.package;
      };
      inherit size;
    }
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
