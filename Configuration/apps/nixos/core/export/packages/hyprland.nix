{ specialArgs, ... }:
{
  programs =
    if specialArgs.ui.env == "hyprland" then
      {
        hyprland = {
          enable = true;
          withUWSM = true;
        };
        hyprlock = {
          enable = true;
        };
      }
    else
      { };
}
