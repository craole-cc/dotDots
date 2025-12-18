{
  user,
  lib,
  ...
}: let
  app = "fastfetch";
  inherit (lib.lists) elem;
  inherit (user.applications) allowed;
  isAllowed = elem app allowed;
in {
  programs.${app}.enable = isAllowed;
  imports = [
    ./settings.nix
    # ./themes.nix
  ];
}
