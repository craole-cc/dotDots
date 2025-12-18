{
  lib,
  user,
  ...
}: let
  app = "git";
  inherit (lib.lists) elem;
  inherit (user.applications) allowed;
  isAllowed = elem app allowed;
in {
  programs.${app}.enable = isAllowed;
  imports = [
    ./core.nix
    ./github.nix
    ./gitui.nix
    ./includes.nix
  ];
}
