{
  host,
  lib,
  ...
}: {
  config = lib.mkIf (host.interface.windowManager == "hyprland") {
    # inherit (import ./components) programs services;

    wayland.windowManager.hyprland =
      {
        enable = true;
      }
      // import ./settings {inherit host lib;}
      // import ./submaps
      // import ./plugins
      // {};
  };
}
