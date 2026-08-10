{config, lib, lix, top, ...}: let
  inherit (lix.modules.core._) mkStaged;
  payload = {

      programs.gitui = {
        enable = config.${top}.inputs.applications.utilities.gitui.enable;
      };
  };
in {
  config = lib.mkMerge (mkStaged {inherit top payload;});
}
