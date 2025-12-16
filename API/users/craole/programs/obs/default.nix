{
  lib,
  user,
  ...
}: let
  app = "obs-studio";
  inherit (lib.lists) elem;
  inherit (user) enable;
  isAllowed = elem app enable;
in {
  programs.${app}.enable = isAllowed;
  imports = [];
}
