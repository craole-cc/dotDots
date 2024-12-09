{ pkgs, config, ... }:
if config.programs.hyprland.enable then
  {
    environment.systemPackages = with pkgs; [
      qalculate-qt
      wlprop
    ];
  }
else
  { }
