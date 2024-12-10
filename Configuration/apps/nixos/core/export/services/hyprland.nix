{ specialArgs, ... }:
if specialArgs.ui.env == "hyprland" then
  {
    services = {
      hypridle = {
        enable = true;
      };
    };
  }
else
  { }
