{ specialArgs, ... }:
if specialArgs.ui.env == "hyprland" then
  {
    programs = {
      hyprland = {
        enable = true;
        withUWSM = true;
      };
      hyprlock = {
        enable = true;
      };
    };
  }
else
  { }
