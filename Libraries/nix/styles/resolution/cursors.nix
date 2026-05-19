{_, ...}: let
  meta = let
    doc = ''
      Cursor resolution (Layer 3).

      Dispatches any cursor input to { light, dark } each { name, package, size }.

      Input shapes accepted:
        ""                        → catppuccin default (generated)
        attrset with `package`    → pass-through, size injected
        attrset with `name`       → package resolved via getPackage
        string                    → registry lookup:
          entry.generated = true  → delegate to catppuccin.cursor
          entry.polarity attrset  → polarity-aware name selection
          else                    → entry.name used for both polarities

      Depends on: styles.filters, styles.resolution.catppuccin, types.predicates.
    '';
    exports = {
      local = {inherit resolve;};
      alias = {resolveCursor = resolve;};
    };
  in {inherit doc exports;};

  inherit (_.content.emptiness) isEmpty;
  inherit (_.attrsets.resolution) getPackage;
  inherit (_.debug.assertions) assertMsgFunc;
  inherit (_.styles.filters) lookup;
  inherit (_.types.predicates) isAttrs isString;

  cursorRegistry = _.styles.queries.cursors.all;

  # ── Helpers ────────────────────────────────────────────────────────────────

  mkBothFromEntry = {
    entry,
    size,
    pkgs,
    ...
  }: let
    resolveName = pol:
      if isAttrs (entry.polarity or null)
      then entry.polarity.${pol}.name
      else let
        valid = assertMsgFunc {
          name = "cursors.mkBothFromEntry";
          assertion = entry ? name;
          message = "cursor entry has no `name` and polarity is not an attrset";
        };
      in
        assert valid; entry.name;
    pkg = getPackage {
      inherit pkgs;
      target = entry.package;
    };
  in {
    light = {
      name = resolveName "light";
      package = pkg;
      inherit size;
    };
    dark = {
      name = resolveName "dark";
      package = pkg;
      inherit size;
    };
  };

  # ── Resolve ───────────────────────────────────────────────────────────────

  resolve = {
    cursor ? "",
    polarity ? "dark",
    size ? 24,
    accent ? "blue",
    flavor ? "mocha",
    pkgs,
  }:
    if isEmpty cursor
    then _.styles.resolution.catppuccin.cursor {inherit accent flavor size pkgs;}
    else if isAttrs cursor && cursor ? package
    then {
      light = cursor // {inherit size;};
      dark = cursor // {inherit size;};
    }
    else if isAttrs cursor && cursor ? name
    then let
      valid = assertMsgFunc {
        name = "cursors.resolve";
        assertion = cursor ? package;
        message = "cursor attrset has `name` but no `package`";
      };
      pkg = assert valid;
        getPackage {
          inherit pkgs;
          target = cursor.package;
        };
    in {
      light = {
        inherit (cursor) name;
        package = pkg;
        inherit size;
      };
      dark = {
        inherit (cursor) name;
        package = pkg;
        inherit size;
      };
    }
    else if isString cursor
    then let
      result = lookup cursor cursorRegistry;
      entry = result.entry;
    in
      if entry.generated or false
      then _.styles.resolution.catppuccin.cursor {inherit accent flavor size pkgs;}
      else mkBothFromEntry {inherit entry size pkgs;}
    else throw "cursors.resolve: unrecognised input `${toString cursor}`";
in
  meta.exports.local
  // {
    __docs = meta.doc;
    __rootAliases = meta.exports.alias;
  }
