{
  config,
  lix,
  pkgs,
  user,
  ...
}: let
  inherit (lix.strings.construction) toJSON;
  inherit (lix.strings.transformation) escapeShellArg;
  inherit (pkgs) writeText;
  inherit (user.theme.palettes.catppuccin) frappe latte;

  configHome = config.xdg.configHome or "${user.home}/.config";
  relativePath = "dms/themes/catppuccin.json";
  name = "catppuccin";
  path = "${configHome}/${relativePath}";

  mkMode = palette: {
    inherit (palette) name background;
    primary = palette.accent;
    primaryText = palette.foreground;
    primaryContainer = palette.surface;
    secondary = palette.accent;
    secondaryText = palette.foreground;
    secondaryContainer = palette.surface;
    tertiary = palette.accent;
    tertiaryText = palette.foreground;
    tertiaryContainer = palette.surface;
    surface = palette.background;
    surfaceText = palette.foreground;
    surfaceVariant = palette.surface;
    surfaceVariantText = palette.muted;
    surfaceTint = palette.accent;
    backgroundText = palette.foreground;
    outline = palette.muted;
    surfaceContainer =
      if palette.variant == "dark"
      then palette.colors.surface0
      else palette.colors.crust;
    surfaceContainerHigh =
      if palette.variant == "dark"
      then palette.colors.surface1
      else palette.colors.mantle;
    surfaceContainerHighest =
      if palette.variant == "dark"
      then palette.colors.surface2
      else palette.colors.surface0;
    error = palette.colors.red;
    warning = palette.colors.yellow;
    info = palette.colors.blue;
    matugen_type = "scheme-tonal-spot";
  };

  # DMS keeps these Catppuccin surfaces and fixed semantic colors while its
  # Matugen integration replaces the accent roles from the active wallpaper.
  theme = {
    dark = mkMode frappe;
    light = mkMode latte;
    matugen_dynamic_accent = true;
  };
  source = writeText "dotdots-dms-catppuccin.json" (toJSON theme);
in {
  catppuccin = {
    inherit name path;
    pathStr = escapeShellArg path;
    configFile.${relativePath} = {inherit source;};
  };
}
