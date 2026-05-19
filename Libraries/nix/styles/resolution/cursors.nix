{_, ...}: let
  meta = let
    doc = ''
      cursors - dispatcher that resolves any cursor input to { light, dark }
      each containing { name, package, size }.

      Input shapes:
        ""         → catppuccin default cursor
        attrset with `package` → pass-through
        attrset with `name`    → resolve package via getPackage
        string     → registry lookup; generated entries delegate to catppuccin resolver
    '';
    exports = {
      local = {inherit resolveCursor;};
      alias = {cursor = resolveCursor;};
    };
  in {inherit doc exports;};

  inherit (_.types.predicates) isAttrs isString;
  inherit (_.content.emptiness) isEmpty;
  inherit (_.attrsets.resolution) getPackage;

  cursorRegistry = _.styles.filters.queries.cursors.all;

  mkBothFromEntry = {
    entry,
    polarity,
    size,
    pkgs,
  }: let
    resolveName = pol:
      if isAttrs (entry.polarity or null)
      then entry.polarity.${pol}.name
      else entry.name or (throw "Cursor entry has no name");
    resolvePackage = _.attrsets.resolution.getPackage {
      inherit pkgs;
      target = entry.package;
    };
  in {
    light = {
      name = resolveName "light";
      package = resolvePackage;
      inherit size;
    };
    dark = {
      name = resolveName "dark";
      package = resolvePackage;
      inherit size;
    };
  };

  resolveCursor = {
    cursor ? "",
    polarity ? "dark",
    size ? 24,
    accent ? "blue",
    flavor ? "mocha",
    pkgs,
  }:
  # 1. empty → catppuccin default
    if isEmpty cursor
    then _.styles.resolution.catppuccin.cursor {inherit accent flavor size pkgs;}
    # 2. attrset passthrough (already has package derivation)
    else if isAttrs cursor && cursor ? package
    then {
      light = cursor // {inherit size;};
      dark = cursor // {inherit size;};
    }
    # 3. attrset with name → resolve package
    else if isAttrs cursor && cursor ? name
    then let
      pkg = getPackage {
        inherit pkgs;
        target = cursor.package or (throw "cursor attrset needs package attr");
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
    # 4. string → registry lookup
    else if isString cursor
    then let
      result = _.styles.filters.lookup cursor cursorRegistry;
      entry = result.entry;
    in
      if entry.generated or false
      then _.styles.resolution.catppuccin.cursor {inherit accent flavor size pkgs;}
      else mkBothFromEntry {inherit entry polarity size pkgs;}
    else throw "resolveCursor: unfamiliar cursor input `${toString cursor}`";
in
  meta.exports.local
  // {
    __docs = meta.doc;
    __rootAliases = meta.exports.alias;
  }
