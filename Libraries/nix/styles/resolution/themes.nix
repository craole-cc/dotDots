{_, ...}: let
  meta = let
    doc = ''
      Theme resolution (Layer 3).

      Dispatches any theme input to { light, dark } each
      { name, scheme, package, polarity, flavor, accent }.
      Catppuccin family entries delegate to the catppuccin resolver.

      Depends on: styles.registry, styles.resolution.catppuccin, attrsets.resolution.
    '';
    exports = {
      local = {inherit resolve resolvePair;};
      alias = {resolveTheme = resolve;};
    };
  in {inherit doc exports;};

  inherit (_.attrsets.predicates) hasAttr;
  inherit (_.attrsets.resolution) getPackage;
  inherit (_.content.emptiness) isEmpty isNotEmpty;
  inherit (_.debug.assertions) withContext;
  inherit (_.styles.registry) lookup;
  inherit (_.types.predicates) isString;

  registry = _.styles.registry.queries.themes.all;

  /**
    Resolve a static (non-catppuccin) theme entry to { name, scheme, package, polarity }.

    Both polarities receive the same resolved record — consumers select the
    slot matching their current polarity.

    # Type
  ```nix
    resolveStatic :: { entry :: attrset, pkgs :: pkgs } -> { name :: string, scheme :: string | null, package :: derivation | null, polarity :: string }
  ```
  */
  resolveStatic = {
    entry,
    pkgs,
  }: {
    inherit (entry) name polarity;
    scheme = entry.scheme or null;
    package =
      if isNotEmpty (entry.package or null)
      then
        getPackage {
          inherit pkgs;
          target = entry.package;
        }
      else null;
  };

  mkBoth = mkOne: args: {
    light = mkOne (args // {polarity = "light";});
    dark = mkOne (args // {polarity = "dark";});
  };

  /**
    Resolve any theme input to a single variant for the given polarity.

    Input shapes accepted:
    - `""`                        → catppuccin default theme for this polarity
    - string (family=catppuccin)  → delegate to catppuccin.mkTheme
    - string (other families)     → static resolved record from registry entry

    # Type
  ```nix
    resolve :: { pkgs :: pkgs, polarity :: string?, theme :: string?, accent :: string | [ string string ] | { light :: string, dark :: string }?, flavor :: string | [ string string ] | { light :: string, dark :: string }? } -> { name :: string, scheme :: string | null, package :: derivation | null, polarity :: string }
  ```

    # Examples
  ```nix
    resolve { inherit pkgs; }
    resolve { inherit pkgs; theme = "rose-pine"; polarity = "light"; }
    resolve { inherit pkgs; theme = "gruvbox-dark"; accent = "sky"; }
  ```
  */
  resolve = {
    pkgs,
    polarity ? "dark",
    theme ? "",
    accent ? null,
    flavor ? null,
  }: let
    fn = {
      name = "themes.resolve";
      context = "resolving theme for ${polarity}";
    };
  in
    if isEmpty theme
    then _.styles.resolution.catppuccin.mkTheme {inherit pkgs polarity accent flavor;}
    else if isString theme
    then let
      inherit (lookup theme registry) entry;
    in
      if (entry.family or null) == "catppuccin"
      then _.styles.resolution.catppuccin.mkTheme {inherit pkgs polarity accent flavor;}
      else resolveStatic {inherit entry pkgs;}
    else
      assert withContext {
        inherit (fn) name context;
        assertion = false;
        message = "expected null or string, got `${toString theme}`";
      }; null;

  /**
    Resolve a theme for both polarities.

    Returns `{ light, dark }` each containing the resolved theme record.

    # Type
  ```nix
    resolvePair :: { pkgs :: pkgs, theme :: string?, accent :: string | [ string string ] | { light :: string, dark :: string }?, flavor :: string | [ string string ] | { light :: string, dark :: string }? } -> { light :: { ... }, dark :: { ... } }
  ```

    # Examples
  ```nix
    resolvePair { inherit pkgs; }
    resolvePair { inherit pkgs; theme = "nord"; }
    resolvePair { inherit pkgs; theme = "catppuccin-mocha"; accent = [ "sapphire" "sky" ]; }
  ```
  */
  resolvePair = mkBoth resolve;
in
  meta.exports.local
  // {
    __docs = meta.doc;
    __rootAliases = meta.exports.alias;
  }
