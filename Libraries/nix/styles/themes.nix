{_, ...}: let
  meta = let
    doc = ''
      Theme resolution (Layer 3).

      Builds theme outputs as either one polarity (`mkOne`) or both polarities
      (`mkPair`). Empty theme input falls back to generated Catppuccin themes.
      Registry entries support normalized alias lookup. Family entries resolve
      to the closest matching theme in the same family for the requested
      polarity.

      Depends on: styles.registry, styles.catppuccin, attrsets.resolution.
    '';
    alias = {
      mkTheme = mkOne;
      mkThemes = mkPair;
      resolveTheme = mkOne;
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
  inherit (_.content.emptiness) isNotEmpty;
  inherit (_.debug.assertions) withContext;
  inherit (_.lists.access) elemAt;
  inherit (_.lists.selection) filter;
  inherit (_.types.predicates) isAttrs;
  inherit (_.styles.registry) mkData mkPolarity;

  mkCatppuccin = _.styles.catppuccin.themes.mkOne;

  data = mkData {
    domain = "themes";
    seed = {};
    groupBy = ["byFamily"];
  };

  inherit (data) normalize groups;
  inherit (data.resolved) lookup;

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

    entry = normalize {
      inherit polarity lookup;
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
              (item.polarity or null) == polarity || (item.polarity or null) == null
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
          inherit pkgs polarity accent flavor;
        }
      else if (resolved.family or null) == "catppuccin"
      then
        mkCatppuccin {
          inherit pkgs polarity accent flavor;
        }
      else {
        inherit (resolved) name;
        polarity = resolved.polarity or polarity;
        scheme = resolved.scheme or null;
        package =
          if isNotEmpty (resolved.package or null)
          then
            getPackage {
              inherit pkgs;
              target = resolved.package;
            }
          else null;
        flavor = resolved.flavor or null;
        accent = resolved.accent or null;
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
