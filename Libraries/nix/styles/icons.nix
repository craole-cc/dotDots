{_, ...}: let
  meta = let
    doc = ''
      Icon resolution (Layer 3).

      Builds icon outputs as either one polarity (`mkOne`) or both polarities
      (`mkPair`). Empty icon input falls back to Candy Icons. Registry entries
      support normalized alias lookup. Family entries resolve to the closest
      matching icon in the same family for the requested polarity.

      Depends on: styles.registry, attrsets.resolution.
    '';
    alias = {
      mkIcon = mkOne;
      mkIcons = mkPair;
    };
    exports = {
      local = {inherit data mkOne mkPair;} // alias;
      inherit alias;
    };
  in {inherit doc exports;};

  inherit (_.attrsets.access) attrNames;
  inherit (_.attrsets.predicates) hasAttr;
  inherit (_.attrsets.resolution) getPackage;
  inherit (_.content.emptiness) isNotEmpty;
  inherit (_.debug.assertions) withContext;
  inherit (_.lists.access) elemAt;
  inherit (_.lists.selection) filter;
  inherit (_.types.predicates) isAttrs;
  inherit (_.styles.registry) mkData mkPolarity;

  data = mkData {
    domain = "icons";
    seed = {icon = "candy-icons";};
    groupBy = ["byFamily"];
  };
  inherit (data) seed normalize groups;
  inherit (data.resolved) lookup;

  mkOne = {
    pkgs,
    polarity ? "dark",
    icon ? null,
  }: let
    fn = {
      name = "icons.mkOne";
      context = "building icon theme for ${polarity}";
    };
    entry = normalize {
      inherit polarity;
      value = icon;
      fallback = seed.icon;
    };
  in
    if isAttrs entry && hasAttr "family" entry
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
              else true
          )
          (attrNames candidates);
      in
        if isNotEmpty samePolarity
        then lookup (elemAt samePolarity 0)
        else null;
      resolved =
        if isNotEmpty candidate
        then candidate
        else lookup seed.icon;
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
