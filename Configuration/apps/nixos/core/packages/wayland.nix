{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkIf;
  enable = with config; programs.hyprland.enable || services.displayManager.sddm.wayland.enable;
in
{
  config = mkIf enable {
    environment.systemPackages = with pkgs; [
      qalculate-qt
      wlprop
    ];

    programs = {
      firefox = {
        enable = true;
      };
    };
  };
}
