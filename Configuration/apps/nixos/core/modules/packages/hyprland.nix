{
  lib,
  pkgs,
  specialArgs,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (lib.attrsets) attrValues;
  inherit (lib.lists) any;
  inherit (specialArgs) host users;
  enable =
    host.desktop == "hyprland"
    || any (user: user.desktop.manager or null == "hyprland") (attrValues users);
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
      systemPackages = with pkgs; [
        kitty
        waybar
      ];
    };
  };
}
