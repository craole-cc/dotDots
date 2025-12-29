{
  host,
  lib,
  lix,
  pkgs,
  user,
  ...
}: let
  inherit (lix.modules.core) mkSudoRules;
  inherit (lix.attrsets.resolution) package;
in {
  # wayland.windowManager = {
  #   hyprland.enable = user.interface.windowManager or null == "hyprland";
  #   sway.enable = user.interface.windowManager or null == "sway";
  #   river.enable = user.interface.windowManager or null == "river";
  #   labwc.enable = user.interface.windowManager or null == "labwc";
  #   wayfire.enable = user.interface.windowManager or null == "wayfire";
  # };

  imports = [
    ./apps.nix
    ./themes.nix

    ./browser
    ./common
    ./editor
    ./fetcher
    ./interface
    ./media
    ./shell
    ./terminal
    ./vsc
  ];
}
