{config, lib, lix, top, ...}: let
  inherit (lix.modules.core._) mkStaged;
  payload = {

      programs.btop = {
        enable = config.${top}.inputs.applications.utilities.btop.enable;
      };
  };
in {
  config = lib.mkMerge (mkStaged {inherit top payload;});
}
