{
  config,
  pkgs,
  style,
  lix,
  ...
}: let
  inherit (config.xdg) configHome;
  inherit (lix.styles.palettes) mkGhosttyPalette;
  inherit (pkgs) writeText;
in {
  ghostty = {
    # DMS provides the `dankcolors` theme and generates its palette.
    matugenTemplateEnabled = true;
    opacity = {
      path = "${configHome}/ghostty/dotdots-opacity";
      fallback = writeText "dotdots-ghostty-opacity" ''
        background-opacity = ${toString style.opacity.terminal.dark}
      '';
    };
  };
}
