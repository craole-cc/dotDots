{
  config,
  lib,
  lix,
  top,
  ...
}: let
  inherit (lix.modules.core.staging) mkStaged;
  payload = {
    programs.nh = {
      enable = config.${top}.resolved.applications.utilities.nh.enable;
      clean = {
        enable = true;
        dates = "daily";
      };
    };
  };
in {
  config = lib.mkMerge (mkStaged {
    inherit top payload;
  });
}
