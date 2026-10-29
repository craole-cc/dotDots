{
  config,
  lix,
  ...
} @ args: let
  inherit (lix.attrsets.access) getAttr;
  inherit (lix.attrsets.transformation) mapAttrs;
  inherit (lix.attrsets.aggregation) mergeSafe;
  inherit (lix.lists.aggregation) concatMap;
  inherit (lix.filesystem.primitives) concat;
  inherit (lix.strings.transformation) escapeShellArg;

  icons = let
    themes = config.themes.icons;
  in {
    dark = rec {
      theme = themes.dark.name;
      name = escapeShellArg theme;
      source = concat {
        root = themes.dark.package;
        stem = ["share" "icons" theme];
      };
    };
    light = rec {
      theme = themes.light.name;
      name = escapeShellArg theme;
      source = "${themes.light.package}/share/icons/${theme}";
    };
    resolved = themes.dark;
  };
  cursors =
    mapAttrs (_mode: resolved: rec {
      theme = resolved.name;
      name = escapeShellArg theme;
      source = "${resolved.package}/share/icons/${theme}";
      inherit (resolved) size;
    })
    config.themes.cursors;

  mkThemeModals = {
    modes ? ["dark" "light"],
    types ? ["icons" "cursors"],
  }: let
    mk = mode: type: let
      selected = getAttr mode (getAttr type {inherit icons cursors;});
    in {"icons/${selected.theme}" = {inherit (selected) source;};};
  in
    concatMap (type: map (mode: mk mode type) modes) types;

  dataFile = mergeSafe (mkThemeModals {});

  resolved = {inherit (config.themes) cursors icons;};
in
  {inherit cursors dataFile icons resolved;}
  // (import ./accent.nix args)
  // (import ./catppuccin.nix args)
  // (import ./foot.nix args)
  // (import ./ghostty.nix args)
  // (import ./helix.nix args)
  // (import ./hermes.nix args)
  // (import ./kitty.nix args)
