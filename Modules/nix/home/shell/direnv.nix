{config, lib, lix, top, ...}: let
  inherit (lix.modules.core.staging) mkStaged;
  payload = {

      programs.direnv = {
        enable = config.${top}.resolved.applications.utilities.direnv.enable;
        silent = true;
        mise.enable = true;
      };
  };
in {
  config = lib.mkMerge (mkStaged {inherit top payload;});
}
