{_, ...}: let
  meta = let
    doc = ''
      icons - dispatcher that resolves any icon input to { light, dark }
      each containing { name, package }.

      Input shapes:
        ""         → default (candy-icons)
        attrset with `package` → pass-through
        attrset with `name`    → resolve package
        string     → registry lookup; polarity-aware entries split by light/dark
    '';
    exports = {
      local = {inherit resolveIcons;};
      alias = {icons = resolveIcons;};
    };
  in {inherit doc exports;};

  inherit (_.types.predicates) isAttrs isString;
  inherit (_.content.emptiness) isEmpty;
  inherit (_.attrsets.resolution) getPackage;

  iconRegistry = _.styles.filters.queries.icons.all;
  defaultIconKey = "candy-icons";

  resolveFromEntry = {
    entry,
    polarity,
    pkgs,
  }: let
    pkg = getPackage {
      inherit pkgs;
      target = entry.package;
    };
    resolveName = pol:
      if isAttrs (entry.polarity or null)
      then entry.polarity.${pol}.name
      else entry.name or (throw "Icon entry `${entry._key or "?"}` has no name");
  in {
    light = {
      name = resolveName "light";
      package = pkg;
    };
    dark = {
      name = resolveName "dark";
      package = pkg;
    };
  };

  resolveIcons = {
    icons ? "",
    polarity ? "dark",
    pkgs,
  }:
    if isEmpty icons
    then let
      entry = iconRegistry.${defaultIconKey} or
        (throw "Default icon entry `${defaultIconKey}` not found in registry");
    in
      resolveFromEntry {inherit entry polarity pkgs;}
    else if isAttrs icons && icons ? package
    then {
      light = icons;
      dark = icons;
    }
    else if isAttrs icons && icons ? name
    then let
      pkg = getPackage {
        inherit pkgs;
        target = icons.package or (throw "icon attrset needs package");
      };
    in {
      light = {
        inherit (icons) name;
        package = pkg;
      };
      dark = {
        inherit (icons) name;
        package = pkg;
      };
    }
    else if isString icons
    then let
      result = _.styles.filters.lookup icons iconRegistry;
    in
      resolveFromEntry {
        entry = result.entry;
        inherit polarity pkgs;
      }
    else throw "resolveIcons: unrecognised icons input `${toString icons}`";
in
  meta.exports.local
  // {
    __docs = meta.doc;
    __rootAliases = meta.exports.alias;
  }
