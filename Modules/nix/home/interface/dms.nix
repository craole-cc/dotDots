{
  config,
  lib,
  top,
  ...
}: {
  config.programs.dank-material-shell.enable =
    lib.mkIf (
      config.${top}.resolved.interface.panel == "dms-shell"
    )
    true;
}
