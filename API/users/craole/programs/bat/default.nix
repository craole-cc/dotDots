{
  user,
  lib,
  ...
}: let
  inherit (lib.lists) elem;
  inherit (user) apps;
  app = "bat";
  enable = elem app apps;
in {
  programs.bat = {inherit enable;};
  imports = [
    ./settings.nix
    # ./themes.nix
  ];
}
