{
  host,
  apps,
  lib,
  lix,
  keyboard,
  paths,
  pkgs,
  user,
  importAll,
  ...
}: let
  app = "hyprland";
  inherit (lib.modules) mkIf mkMerge;
  isAllowed = app == (user.interface.windowManager or null);
in {
  config = mkIf isAllowed (mkMerge [
    {
      wayland.windowManager.hyprland = mkMerge [
        {enable = true;}
        (import ./settings {
          inherit
            host
            lib
            lix
            apps
            user
            keyboard
            mkMerge
            ;
        })
        (import ./submaps {inherit mkMerge;})
      ];
    }
    (import ./addons {inherit mkMerge pkgs paths;})
    # (importAll ../addons)
  ]);
}
