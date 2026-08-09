{
  config,
  lix,
  lib,
  top,
  ...
}: let
  inherit (lix.modules.construction) mkIf;
  inherit (config.${top}.inputs.interface) panel;
  isDmsShell = panel == "dms-shell";
in {
  config = lib.mkMerge [
    (mkIf isDmsShell {
    programs.dms-shell.enable = true;
  })
    {
      ${top}.output = mkIf isDmsShell {
    programs.dms-shell.enable = true;
  };
    }
  ];
}
