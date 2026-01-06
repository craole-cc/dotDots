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
      (import ./settings {inherit host lib lix mkMerge;})
      # (import ./submaps)
      # (import ./plugins)
    ];
    home.sessionVariables = {
      # XDG_CURRENT_DESKTOP = "hyprland";
    };
  };
}
