{lix, ...}: let
  inherit (lix.modules.construction) mkForce;

  light = "Catppuccin Latte";
  dark = "Catppuccin Frappe";
in {
  settings = {
    # Ghostty can follow the desktop appearance when both variants are declared.
    # Force this value so generic theming modules cannot collapse the pair to a
    # single static theme.
    theme = mkForce "light:${light},dark:${dark}";
    window-theme = "system";
  };
}
