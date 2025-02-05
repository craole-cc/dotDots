{
  config,
  lib,
  ...
}:
with lib;
with config.dots.lib.get.host.interface;
{
  config = {
    programs = {
      hyprland.enable = desktop.manager == "hyprland";
    };
  };
}
