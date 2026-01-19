{
  host,
  lib,
  lix,
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
            user
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
