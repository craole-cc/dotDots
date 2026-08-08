{
  pkgs,
  lib,
  config,
  top,
  ...
}: let
  inherit (lib.lists) optionals;
in {
  programs.yazi = {
    enable = config.${top}.inputs.applications.utilities.yazi.enable;
    shellWrapperName = "y";
  };

  home = {
    packages = with pkgs.yaziPlugins; optionals pkgs.stdenv.isDarwin [mactag];
  };
}
