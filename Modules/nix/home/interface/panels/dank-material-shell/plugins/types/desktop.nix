{
  config,
  pkgs,
  ...
}: let
  hyprland = config._.resolved.interface.managers.hyprland.defined.enable or false;
in {
  plugins = {
    dankClight.enable = true;
    dankDesktopWeather.enable = true;
    dankHyprlandWindows.enable = hyprland;
    displaySettings.enable = hyprland;
    showDesktop.enable = hyprland;
    dmsScreenshot.enable = true;
  };

  packages = with pkgs; [clight];
}
