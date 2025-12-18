{
  user,
  lib,
  ...
}: let
  inherit (lib.lists) elem;
  inherit (user.applications) allowed;
  app = "zed-editor";
  isAllowed = elem app allowed;
in {
  programs.${app}.enable = isAllowed;
  imports = [
    # ./settings.nix
    ./extensions.nix
  ];
}
