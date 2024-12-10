{ pkgs, config, ... }:
let
  isWayland = with config; programs.hyprland.enable || services.displayManager.sddm.wayland.enable;
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
