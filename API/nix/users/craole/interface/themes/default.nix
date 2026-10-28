let
  inherit (import ./styles) palettes;
  inherit (palettes.catppuccin) frappe latte;

  modes = let
    light = {
      palette = latte;
      icon = "buuf-nestort";
      cursor = "material-cursors";
      opacity = {
        terminal = 0.80;
        editor = 0.97;
      };
    };
    dark = {
      palette = frappe;
      icon = "candy-icons";
      cursor = "catppuccin-cursors";
      opacity = {
        terminal = 0.75;
        editor = 0.94;
      };
    };
    default = dark;
    autoSwitch = true;
  in {inherit dark light default autoSwitch;};
in {theme = {inherit palettes modes;};}
