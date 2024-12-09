{ config, specialArgs, ... }:
if specialArgs.ui.env == "hyprland" || config.programs.hyprland.enable then
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
    services = {
      hypridle = {
        enable = true;
      };
    };
  }
else
  { }
