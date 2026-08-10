{
  config,
  lib,
  lix,
  top,
  ...
}: let
  enable = config.${top}.inputs.applications.utilities.bat.enable;
  inherit (lix.modules.core._) mkStaged;

  payload = {
    programs.bat = {
      inherit enable;
      config.pager = "less -F";
    };
  };
in {
  config = lib.mkMerge (mkStaged {inherit top payload;});
}
