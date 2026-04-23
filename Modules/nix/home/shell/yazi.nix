{
  pkgs,
  lib,
  ...
}: let
  inherit (lib.lists) optionals;
in {
  programs.yazi = {
    enable = true;
    shellWrapperName = "y";
  };

  home = {
    packages = with pkgs.yaziPlugins; optionals pkgs.stdenv.isDarwin [mactag];
  };
}
