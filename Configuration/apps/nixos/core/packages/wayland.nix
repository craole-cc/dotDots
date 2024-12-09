{ pkgs, config, ... }:
let
  isWayland = config.programs.hyprland.enable;
in
{
  environment.systemPackages =
    if isWayland then
      with pkgs;
      [
        brave
        qalculate-qt
        wlprop
      ]
    else
      [ ];
      
  programs =
    if isWayland then
      {
        firefox = {
          # enable = true;
        };
      }
    else
      { };
}
