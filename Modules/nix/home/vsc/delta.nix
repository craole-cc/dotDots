{config, lib, lix, top, ...}: let
  inherit (lix.modules.core._) mkStaged;
  payload = {

      programs.delta = {
        enable = config.${top}.inputs.applications.utilities.delta.enable;
        enableGitIntegration = true;
        enableJujutsuIntegration = true;
      };
  };
in {
  config = lib.mkMerge (mkStaged {inherit top payload;});
}
