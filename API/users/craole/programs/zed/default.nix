{
  user,
  lib,
  ...
}: let
  inherit (lib.lists) elem;
  inherit (user) enable;
  app = "zed-editor";
  isAllowed = elem app enable;
in {
  programs.${app}.enable = isAllowed;
  imports = [
    # ./settings.nix
    ./extensions.nix
  ];
}
