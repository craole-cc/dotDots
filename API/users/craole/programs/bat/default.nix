{
  user,
  lib,
  ...
}: let
  inherit (lib.lists) elem;
  inherit (user) enable;
  app = "bat";
  isAllowed = elem app enable;
in {
  programs.${app}.enable = isAllowed;
  imports = [
    ./settings.nix
    # ./themes.nix
  ];
}
