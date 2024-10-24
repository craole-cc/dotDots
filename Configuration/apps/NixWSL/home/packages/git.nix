{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [<home-manager/nixos>];

  home-manager.users.craole = {pkgs, ...}: {
    programs.git = {
      userName = "craole-cc";
      userEmail = "craole@tuta.io";
      signing.key = "8CF1774E62AA8FFF3A61C57DB6839887B60197B0";
    };
  };
}
