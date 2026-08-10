{config, lib, lix, top, ...}: let
  inherit (lix.modules.core.staging) mkStaged;
  payload = {

      programs.home-manager = {
        enable = config.${top}.inputs.applications.utilities.home-manager.enable;
        # autoExpire.enable = true;
      };
      news.display = "silent";
      manual.html.enable = true;
  };
in {
  config = lib.mkMerge (mkStaged {inherit top payload;});
}
