{config, lib, lix, top, ...}: let
  inherit (lix.modules.core._) mkStaged;
  payload = {

      programs = {
        gh = {
          enable = config.${top}.inputs.applications.utilities.github.enable;
        };
        gh-dash = {
          enable = config.${top}.inputs.applications.utilities.github.enable;
        };
      };
  };
in {
  config = lib.mkMerge (mkStaged {inherit top payload;});
}
