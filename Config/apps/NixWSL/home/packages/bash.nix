{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [<home-manager/nixos>];

  home-manager.users.craole = {pkgs, ...}: {
    programs.bash = {
      enable = true;
      shellAliases = {
        NixOS-WSL = "cd $wsl_conf && sh init";
        fmt_wsl_conf = "alejandra format $wsl_conf --quiet --exclude $wsl_conf/archive";
      };
    };
  };
}
