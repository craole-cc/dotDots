{_, ...}: let
  meta = let
    doc = ''
      Style resolution (Layer 3).

      Resolvers for all style domains. Each resolver accepts user input
      (string | package | { name, package }) and returns a fully resolved
      attrset ready for consumption by mkStyle.

      ## Functions

      - `icons`   - { pkgs, light?, dark? } -> { light, dark } each { name, package }
      - `cursors` - { pkgs, light?, dark?, size?, accent?, variants? } -> { light, dark } each { name, package, size }
      - `opacity` - { light?, dark? } -> { light, dark } each { terminal, popups }
    '';
    exports = {
      local = {
        inherit
          icons
          cursors
          opacity
          ;
      };
      alias = {
        resolveIcons = icons;
        resolveCursors = cursors;
        resolveOpacity = opacity;
      };
    };
  in {inherit doc exports;};

  inherit (_.attrsets.construction) optionalAttrs;
  inherit (_.attrsets.aggregation) recursiveUpdate;
  inherit (_.attrsets.resolution) getPackage;
  inherit (_.content.emptiness) isEmpty isNotEmpty;
  inherit (_.strings.transformation) toPascal;
  inherit (_.styles.filters) lookup;
  inherit (_.types.predicates) isAttrs;

  # ── Icons ──────────────────────────────────────────────────────────────────

  resolveOne = {
    pkgs,
    polarity,
    input,
    size ? null,
    accent ? null,
    variants ? null,
  }: let
    catppuccinArgs =
      {inherit pkgs polarity;}
      // optionalAttrs (isNotEmpty size) {inherit size;}
      // optionalAttrs (isNotEmpty accent) {inherit accent;}
      // optionalAttrs (isNotEmpty variants) {inherit variants;};
  in
    if isEmpty input
    then resolveCatppuccin catppuccinArgs
    else if isAttrs input && input ? package
    then input
    else if isAttrs input && input ? name
    then {
      inherit (input) name;
      package = getPackage {
        inherit pkgs;
        target = input.name;
      };
      size =
        if input ? size
        then input.size
        else if isNotEmpty size
        then size
        else 24;
    }
    else let
      result = lookup input _.styles.filters.queries.cursors.all;
    in
      if isNotEmpty result
      then
        if result.key == "catppuccin"
        then resolveCatppuccin catppuccinArgs
        else {
          name = result.entry.names.${polarity} or result.key;
          package = getPackage {
            inherit pkgs;
            target = result.entry.names.package;
          };
          size =
            if isNotEmpty size
            then size
            else (result.entry.size or 24);
        }
      else {
        name = input;
        package = getPackage {
          inherit pkgs;
          target = input;
        };
        size =
          if isNotEmpty size
          then size
          else 24;
      };
  resolve = {
    pkgs,
    light ? {},
    dark ? {},
    size ? null,
    accent ? null,
    variants ? null,
  }: let
    args = polarity: input:
      {inherit pkgs polarity input;}
      // optionalAttrs (isNotEmpty size) {inherit size;}
      // optionalAttrs (isNotEmpty accent) {inherit accent;}
      // optionalAttrs (isNotEmpty variants) {inherit variants;};
  in {
    light = resolveOne (args "light" light);
    dark = resolveOne (args "dark" dark);
  };
in
  meta.exports.local
  // {
    __docs = meta.doc;
    __rootAliases = meta.exports.alias;
  }
