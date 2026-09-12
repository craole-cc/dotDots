let
  alpha = 0.95;
in {
  # DMS writes the active light/dark palette here. The DMS module seeds a
  # Frappé-like fallback before Foot starts, then Matugen owns subsequent
  # updates. Foot always reads the generated palette as its active theme.
  include = "~/.config/foot/dank-colors.ini";
  colors-dark.alpha = alpha;

  cursor = {
    style = "beam";
    blink = "yes";
    blink-rate = 500;
    beam-thickness = 1.5;
  };
}
