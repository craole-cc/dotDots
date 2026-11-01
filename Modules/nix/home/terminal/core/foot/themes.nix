{
  opacity ? {
    dark = 1.0;
    light = 1.0;
  },
}: {
  # DMS writes the active light/dark palette here. The DMS module seeds a
  # Frappé-like fallback before Foot starts, then Matugen owns subsequent
  # updates. Foot always reads the generated palette as its active theme.
  main.include = "~/.config/foot/dank-colors.ini";
  colors-dark.alpha = opacity.dark;
  colors-light.alpha = opacity.light;

  cursor = {
    style = "beam";
    blink = "yes";
    blink-rate = 500;
    beam-thickness = 1.5;
  };
}
