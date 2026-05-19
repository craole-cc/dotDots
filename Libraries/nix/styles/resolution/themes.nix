{_, ...}: let
  meta = let
    doc = ''
      Theme resolution (Layer 3).

      Dispatches any theme input to { light, dark } each
      { name, scheme, package, polarity }.

      Input shapes accepted:
        ""                          → catppuccin default
        string (family=catppuccin)  → delegate to catppuccin.theme
        string (other families)     → static pair from registry entry

      Depends on: styles.filters, styles.resolution.catppuccin, attrsets.resolution.
    '';
    exports = {
      local = {inherit resolve;};
      alias = {resolveTheme = resolve;};
    };
  in {inherit doc exports;};

  inherit (_.content.emptiness) isEmpty;
  inherit (_.attrsets.resolution) getPackage;
  inherit (_.debug.assertions) assertMsgFunc;
  inherit (_.styles.filters) lookup;
  inherit (_.types.predicates) isString;

  themeRegistry = _.styles.queries.themes.all;

  # ── Helpers ────────────────────────────────────────────────────────────────

  # Non-catppuccin entries have a single polarity; both slots get the same
  # resolved record — consumers pick the one matching their current polarity.
  staticPair = {
    entry,
    pkgs,
  }: let
    pkg =
      if entry.package or null != null
      then
        getPackage {
          inherit pkgs;
          target = entry.package;
        }
      else null;
    resolved = {
      name = entry.name;
      scheme = entry.scheme or null;
      polarity = entry.polarity;
      package = pkg;
    };
  in {
    light = resolved;
    dark = resolved;
  };

  # ── Resolve ───────────────────────────────────────────────────────────────

  resolve = {
    theme ? "",
    accent ? "blue",
    flavor ? "mocha",
    pkgs,
  }:
    if isEmpty theme
    then _.styles.resolution.catppuccin.theme {inherit accent flavor pkgs;}
    else if isString theme
    then let
      result = lookup theme themeRegistry;
      entry = result.entry;
    in
      if (entry.family or null) == "catppuccin"
      then _.styles.resolution.catppuccin.theme {inherit accent flavor pkgs;}
      else staticPair {inherit entry pkgs;}
    else throw "themes.resolve: expected a string, got `${toString theme}`";
in
  meta.exports.local
  // {
    __docs = meta.doc;
    __rootAliases = meta.exports.alias;
  }
