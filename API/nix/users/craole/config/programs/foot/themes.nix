{style}: {
  include = "~/.config/foot/theme.ini";
  colors-dark.alpha = style.opacity.terminal.dark;
  colors-light.alpha = style.opacity.terminal.light;

  cursor = {
    style = "beam"; # Options: block, underline, beam
    blink = "yes";
  };
}
