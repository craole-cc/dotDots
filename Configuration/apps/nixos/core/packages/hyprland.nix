{
  lib,
  pkgs,
  specialArgs,
  ...
}:
let
  inherit (lib.modules) mkIf;
  enable = specialArgs.host.desktop == "hyprland";
in
{
  config = mkIf enable {
    programs = {
      hyprland = {
        enable = true;
        withUWSM = true;
      };
      hyprlock = {
        enable = true;
      };
    };
    environment = {
      systemPackages = with pkgs; [ kitty ];
    };
  };
}
