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
  inherit (_.attrsets.merging) recursiveUpdate;
  inherit (_.attrsets.resolution) getPackage;
  inherit (_.content.empty) isEmpty isNotEmpty;
  inherit (_.strings.transformation) toPascal;
  inherit (_.styles.filters) lookup;
  inherit (_.types.predicates) isAttrs;

  # ── Icons ──────────────────────────────────────────────────────────────────

  resolveOneIcon = pkgs: input:
    if isEmpty input
    then {}
    else if isAttrs input && input ? package
    then input
    else if isAttrs input && input ? name
    then {
      inherit (input) name;
      package = getPackage {
        inherit pkgs;
        target = input.name;
      };
    }
    else let
      result = lookup input _.styles.filters.queries.icons.all;
    in
      if isNotEmpty result
      then {
        name = result.key;
        package = getPackage {
          inherit pkgs;
          target = result.entry.names.package;
        };
      }
      else {
        name = input;
        package = getPackage {
          inherit pkgs;
          target = input;
        };
      };

  icons = {
    pkgs,
    light ? {},
    dark ? {},
  }: {
    light = resolveOneIcon pkgs light;
    dark = resolveOneIcon pkgs dark;
  };

  # ── Cursors ────────────────────────────────────────────────────────────────

  resolveCatppuccin = {
    pkgs,
    polarity,
    accent ? "teal",
    variants ? {
      light = "latte";
      dark = "frappe";
    },
    size ? 24,
  }: let
    variant = variants.${polarity};
  in {
    name = "catppuccin-${variant}-${accent}-cursors";
    package = pkgs.catppuccin-cursors.${variant + (toPascal accent)};
    inherit size;
  };

  resolveOneCursor = {
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

  cursors = {
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
    light = resolveOneCursor (args "light" light);
    dark = resolveOneCursor (args "dark" dark);
  };

  # ── Opacity ────────────────────────────────────────────────────────────────

  opacity = {
    light ? {},
    dark ? {},
  }: let
    base = {
      terminal = 0.9;
      popups = 0.95;
    };
  in
    recursiveUpdate {
      light = base;
      dark = base;
    } {inherit light dark;};
in
  meta.exports.local
  // {
    __docs = meta.doc;
    __rootAliases = meta.exports.alias;
  }
