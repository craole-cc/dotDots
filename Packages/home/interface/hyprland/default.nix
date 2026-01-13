{
  user,
  lib,
  lix,
  host,
  ...
}: let
  app = "hyprland";
  inherit (lib.modules) mkIf mkMerge;
  isAllowed = app == (user.interface.windowManager or null);
in {
  config = mkIf isAllowed {
    wayland.windowManager.hyprland = mkMerge [
      {enable = true;}
      # (import ./components {inherit mkMerge;})
      (import ./settings {inherit host user lib lix;})
      (import ./submaps {inherit mkMerge;})
      # (import ./plugins)
    ];
  };
}
