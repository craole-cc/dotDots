{config, lib, lix, top, ...}: let
  inherit (lix.modules.core._) mkStaged;
  payload = {

      programs.direnv = {
        enable = config.${top}.inputs.applications.utilities.direnv.enable;
        silent = true;
        mise.enable = true;
      };
  };
in {
  config = lib.mkMerge (mkStaged {inherit top payload;});
}
