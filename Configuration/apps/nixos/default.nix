{ config, specialArgs, ... }:
let
  hyprEnabled = config.programs.hyprland.enable;
in
{
  imports = [
    ./apps
    ./hosts
    ./libraries
    ./services
    ./ui
    ./users
  ];

  programs = {
    hyprland = {
      enable = specialArgs.ui.env == "hyprland";
      withUWSM = hyprEnabled;
    };
    hyprlock = {
      enable = hyprEnabled;
    };
  };
  services = {
    hypridle = {
      enable = hyprEnabled;
    };
  };
}
