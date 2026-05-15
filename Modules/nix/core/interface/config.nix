{
  config,
  lix,
  top,
  ...
}: let
  inherit (lix.modules.construction) mkIf;
  inherit (config.${top}.interface) panel compositor;
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
