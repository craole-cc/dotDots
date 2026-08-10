{
  pkgs,
  lib,
  config,
  lix,
  top,
  ...
}: let
  inherit (lix.modules.core.staging) mkStaged;
  inherit (lib.lists) optionals;
  payload = {
    programs.yazi = {
      enable = config.${top}.inputs.applications.utilities.yazi.enable;
      shellWrapperName = "y";
    };

    home.packages = with pkgs.yaziPlugins; optionals pkgs.stdenv.isDarwin [mactag];
  };
in {
  config = lib.mkMerge (mkStaged {
    inherit top payload;
  });
}
