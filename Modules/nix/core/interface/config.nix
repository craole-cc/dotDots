{
  config,
  lix,
  lib,
  top,
  ...
}: let
  inherit (config.${top}.resolved.interface) panel;
  isDmsShell = panel == "dms-shell";
  payload = {
    programs.dms-shell.enable = true;
  };
  inherit (lix.modules.core.staging) mkStaged;
in {
  config = lib.mkMerge (mkStaged {
    inherit top payload;
    condition = isDmsShell;
  });
}
