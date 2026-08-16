{
  config,
  lib,
  lix,
  top,
  ...
}: let
  inherit (lix.modules.core.staging) mkStaged;
  payload = {
    programs.gitui = {
      enable = config.${top}.resolved.applications.utilities.gitui.enable;
    };
  };
in {
  config = lib.mkMerge (mkStaged {inherit top payload;});
}
