{
  user,
  lix,
  lib,
  config,
  host,
  ...
}: let
  app = "hyprland";
  inherit (lib.modules) mkIf;
  inherit (lix.attrsets.predicates) waylandEnabled;

  isAllowed =
    waylandEnabled {
      inherit config;
      interface = user.interface or {};
    }
    && (user.interface.windowManager or null) == app;
in {
  config = mkIf true {
    wayland.windowManager.hyprland =
      {enable = true;}
      // import ./settings {inherit host lib;}
      // import ./submaps
      // import ./plugins
      // {};
  };
}
