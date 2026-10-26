{lix}: let
  inherit (lix.modules.construction) mkForce;
in {
  userSettings = {
    theme = mkForce {
      mode = "system";
      light = "DankShell Light";
      dark = "DankShell Dark";
    };

    icon_theme = mkForce {
      light = "Catppuccin Latte";
      dark = "Catppuccin Frappé";
    };
  };
}
