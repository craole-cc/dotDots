{
  lix,
  interface,
  ...
}: let
  inherit (lix.modules.construction) mkIf;
  inherit (interface.ui) panel compositor;
  isDank = panel == "dms-shell";
in {
  config = mkIf isDank {
    programs.dms-shell.enable = true;
    services.displayManager.dms-greeter = {
      enable = true;
      compositor.name = compositor.window or compositor.desktop;
    };
  };
}
