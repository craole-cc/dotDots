{
  lib,
  user,
  ...
}: let
  app = "helix";
  inherit (lib.lists) elem;
  inherit (user.applications) allowed;
  isAllowed = elem app allowed;
in {
  programs.${app}.enable = isAllowed;
  imports = [
    ./editor.nix
    ./keybindings.nix
    ./languages.nix
    ./themes.nix
  ];
}
