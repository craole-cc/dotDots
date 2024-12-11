{ config, ... }:
let
  # enable = specialArgs.host.desktop == "hyprland";
  enable = config.programs.hyprland.enable;
in
{
  services =
    if enable then
      {
        hypridle = {
          enable = true;
        };
      }
    else
      { };
}
