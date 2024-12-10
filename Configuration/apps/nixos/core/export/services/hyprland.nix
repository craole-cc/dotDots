{ specialArgs, ... }:
{
  services =
    if specialArgs.ui.env == "hyprland" then
      {
        hypridle = {
          enable = true;
        };
      }
    else
      { };
}
