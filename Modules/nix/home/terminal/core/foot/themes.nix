{
  style,
  lix,
}: let
  inherit (lix.modules.construction) mkForce;
in {
  # DMS writes the active light/dark palette here. The DMS module seeds a
  # Frappé-like fallback before Foot starts, then Matugen owns subsequent
  # updates. Foot always reads the generated palette as its active theme.
  main.include = mkForce "~/.config/foot/dank-colors.ini";
  colors-dark.alpha = style.opacity.terminal.dark;
  colors-light.alpha = style.opacity.terminal.light;

  cursor = {
    style = "beam";
    blink = "yes";
    blink-rate = 500;
    beam-thickness = 1.5;
  };
}
