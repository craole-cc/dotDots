{
  lib,
  user,
  ...
}: let
  app = "git";
  inherit (lib.lists) elem;
  inherit (user) enable;
  isAllowed = elem app enable;
in {
  programs.${app}.enable = isAllowed;
  imports = [
    ./core.nix
    ./github.nix
    ./gitui.nix
    ./includes.nix
  ];
}
