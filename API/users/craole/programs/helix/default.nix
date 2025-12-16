{
  lib,
  user,
  ...
}: let
  app = "helix";
  inherit (lib.lists) elem;
  inherit (user) enable;
  isAllowed = elem app enable;
in {
  programs.${app}.enable = isAllowed;
  imports = [
    ./editor.nix
    ./keybindings.nix
    ./languages.nix
    ./themes.nix
  ];
}
