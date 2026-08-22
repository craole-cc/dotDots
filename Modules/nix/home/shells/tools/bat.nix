{
  config,
  lib,
  lix,
  top,
  ...
}: let
  enable = config.${top}.resolved.applications.utilities.bat.enable;
  inherit (lix.modules.core.staging) mkStaged;

  payload = {
    programs.bat = {
      inherit enable;
      config.pager = "less -F";
    };
  };
in {
  config = lib.mkMerge (mkStaged {
    inherit top payload;
  });
}
