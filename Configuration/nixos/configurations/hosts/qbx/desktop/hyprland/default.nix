{ config, lib, ... }:
let
  inherit (lib.modules) mkIf;
  cfgEnabled = config.dots.interface.desktopEnvironment == "hyprland";
in
{
  config = mkIf cfgEnabled {
    programs.hyprland = {
      enable = true;
      withUWSM = true;
    };
  };
}
