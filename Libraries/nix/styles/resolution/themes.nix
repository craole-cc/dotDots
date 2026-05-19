{_, ...}: let
  meta = let
    doc = ''
      themes - dispatcher that resolves a theme string to { light, dark }
      each containing { name, scheme, package, polarity }.

      Catppuccin family entries delegate to the catppuccin resolver so accent
      and flavor are honoured. All other entries return static { light, dark }
      derived from the entry's own polarity field.
    '';
    exports = {
      local = {inherit resolveTheme;};
      alias = {theme = resolveTheme;};
    };
  in {inherit doc exports;};

  inherit (_.types.predicates) isString;
  inherit (_.content.emptiness) isEmpty;
  inherit (_.attrsets.resolution) getPackage;

  themeRegistry = _.styles.filters.queries.themes.all;

  # For non-catppuccin entries: build a { light, dark } from a single static entry.
  # If polarity="light" the entry goes in light; for "dark" in dark.
  # Both slots get populated (fallback to opposite when only one exists).
  staticPair = {
    entry,
    pkgs,
  }: let
    resolved = {
      name = entry.name;
      scheme = entry.scheme or null;
      polarity = entry.polarity;
      package =
        if entry.package or null != null
        then
          getPackage {
            inherit pkgs;
            target = entry.package;
          }
        else null;
    };
  in {
    light = resolved;
    dark = resolved;
  };

  resolveTheme = {
    theme ? "",
    accent ? "blue",
    flavor ? "mocha",
    pkgs,
  }:
    if isEmpty theme
    then _.styles.resolution.catppuccin.theme {inherit accent pkgs;}
    else if isString theme
    then let
      result = _.styles.filters.lookup theme themeRegistry;
      entry = result.entry;
    in
      if (entry.family or null) == "catppuccin"
      then
        # Derive the catppuccin flavor from the entry key/name
        # (entry key is e.g. "catppuccin-mocha"; pass flavor override through)
        _.styles.resolution.catppuccin.theme {inherit accent flavor pkgs;}
      else staticPair {inherit entry pkgs;}
    else throw "resolveTheme: expected a string, got `${toString theme}`";
in
  meta.exports.local
  // {
    __docs = meta.doc;
    __rootAliases = meta.exports.alias;
  }
