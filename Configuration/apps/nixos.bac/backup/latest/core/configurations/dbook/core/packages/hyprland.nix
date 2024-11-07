{ config, ... }:
let
  # enable = config.DOTS.interface.manager == "hyprland";
  enable = false;
in
{
  programs = {
    hyprland = {
      inherit enable;
    };
    hyprlock = {
      inherit enable;
    };
  };

}
