{
  host,
  lib,
  lix,
  keyboard,
  paths,
  pkgs,
  user,
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
            # user
            keyboard
            mkMerge
            ;
        })
        (import ./submaps {inherit mkMerge;})
        (import ./plugins)
      ];
    }
    (import ./components {inherit mkMerge pkgs paths;})
  ]);
}
