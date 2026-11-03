{
  config,
  pkgs,
  style,
  lix,
  ...
}: let
  inherit (config.xdg) configHome;
  inherit (pkgs) writeText;
  inherit (lix.styles.palettes) mkKittyPalette;
in {
  kitty = {
    # Kitty loads DMS-generated dank-tabs.conf and dank-theme.conf when enabled.
    opacity = {
      path = "${configHome}/kitty/dotdots-opacity.conf";
      fallback = writeText "dotdots-kitty-opacity.conf" ''
        background_opacity ${toString style.opacity.terminal.dark}
      '';
    };
  };
}
