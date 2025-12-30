{
  user,
  lib,
  host,
  ...
}: let
  app = "hyprland";
  inherit (lib.modules) mkIf;
  isAllowed = (user.interface.windowManager or null) == app;
in {
  config = mkIf isAllowed {
    wayland.windowManager.hyprland =
      {enable = true;}
      // import ./settings {inherit host lib;}
      // import ./submaps
      // import ./plugins
      // {};
  };
}
