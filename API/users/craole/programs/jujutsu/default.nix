{
  lib,
  user,
  ...
}: let
  app = "jujutsu";
  inherit (lib.lists) elem;
  inherit (user) enable;
  isAllowed = elem app enable;
in {
  programs.${app}.enable = isAllowed;
  imports = [
    ./core.nix
    ./jjui.nix
  ];
}
