{config, lib, lix, top, ...}: let
  inherit (lix.modules.core.staging) mkStaged;
  payload = {

      programs = {
        gh = {
          enable = config.${top}.resolved.applications.utilities.github.enable;
        };
        gh-dash = {
          enable = config.${top}.resolved.applications.utilities.github.enable;
        };
      };
  };
in {
  config = lib.mkMerge (mkStaged {inherit top payload;});
}
