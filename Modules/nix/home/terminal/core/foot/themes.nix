{
  opacity ? {
    dark = 1.0;
    light = 1.0;
  },
}: {
  # DMS seeds the fallback; the appearance synchroniser maintains both modes
  # with contrast correction for the configured background opacity.
  main.include = "~/.config/foot/dotdots-colors.ini";
  colors-dark.alpha = opacity.dark;
  colors-light.alpha = opacity.light;

  cursor = {
    style = "beam";
    blink = "yes";
    blink-rate = 500;
    beam-thickness = 1.5;
  };
}
