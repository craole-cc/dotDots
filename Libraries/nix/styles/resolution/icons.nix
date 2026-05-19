{_, ...}: let
  meta = let
    doc = ''
      Icon resolution (Layer 3).

      Dispatches any icon input to { light, dark } each { name, package }.

      Input shapes accepted:
        ""                        → default (candy-icons)
        attrset with `package`    → pass-through
        attrset with `name`       → package resolved via getPackage
        string                    → registry lookup:
          entry.polarity attrset  → polarity-aware name selection
          else                    → entry.name used for both polarities

      Depends on: styles.filters, attrsets.resolution, types.predicates.
    '';
    exports = {
      local = {inherit resolve;};
      alias = {resolveIcons = resolve;};
    };
  in {inherit doc exports;};

  inherit (_.content.emptiness) isEmpty;
  inherit (_.attrsets.resolution) getPackage;
  inherit (_.debug.assertions) assertMsgFunc;
  inherit (_.styles.filters) lookup;
  inherit (_.types.predicates) isAttrs isString;

  iconRegistry = _.styles.queries.icons.all;
  defaultIconKey = "candy-icons";

  # ── Helpers ────────────────────────────────────────────────────────────────

  resolveFromEntry = {
    entry,
    pkgs,
    ...
  }: let
    valid = assertMsgFunc {
      name = "icons.resolveFromEntry";
      assertion = entry ? package;
      message = "icon entry `${entry.name or "?"}` has no `package`";
    };
    pkg = assert valid;
      getPackage {
        inherit pkgs;
        target = entry.package;
      };
    resolveName = pol:
      if isAttrs (entry.polarity or null)
      then entry.polarity.${pol}.name
      else let
        hasName = assertMsgFunc {
          name = "icons.resolveFromEntry";
          assertion = entry ? name;
          message = "icon entry has no `name` and polarity is not an attrset";
        };
      in
        assert hasName; entry.name;
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

  # ── Resolve ───────────────────────────────────────────────────────────────

  resolve = {
    icons ? "",
    polarity ? "dark",
    pkgs,
  }:
    if isEmpty icons
    then let
      valid = assertMsgFunc {
        name = "icons.resolve";
        assertion = iconRegistry ? ${defaultIconKey};
        message = "default icon entry `${defaultIconKey}` not found in registry";
      };
      entry = assert valid; iconRegistry.${defaultIconKey};
    in
      resolveFromEntry {inherit entry pkgs;}
    else if isAttrs icons && icons ? package
    then {
      light = icons;
      dark = icons;
    }
    else if isAttrs icons && icons ? name
    then let
      valid = assertMsgFunc {
        name = "icons.resolve";
        assertion = icons ? package;
        message = "icon attrset has `name` but no `package`";
      };
      pkg = assert valid;
        getPackage {
          inherit pkgs;
          target = icons.package;
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
      result = lookup icons iconRegistry;
    in
      resolveFromEntry {
        entry = result.entry;
        inherit pkgs;
      }
    else throw "icons.resolve: unrecognised input `${toString icons}`";
in
  meta.exports.local
  // {
    __docs = meta.doc;
    __rootAliases = meta.exports.alias;
  }
