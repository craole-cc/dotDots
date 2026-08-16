{
  config,
  lib,
  lix,
  top,
  ...
}: let
  inherit (lix.modules.core.staging) mkStaged;
  payload = {
    programs.btop = {
      enable = config.${top}.resolved.applications.utilities.btop.enable;
    };
  };
in {
  config = lib.mkMerge (mkStaged {inherit top payload;});
}
