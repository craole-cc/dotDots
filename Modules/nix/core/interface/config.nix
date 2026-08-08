{
  config,
  lix,
  top,
  ...
}: let
  inherit (lix.modules.construction) mkIf;
  inherit (config.${top}.interface) panel;
  isDmsShell = panel == "dms-shell";
in {
  config = mkIf isDmsShell {
    programs.dms-shell.enable = true;
  };
}
