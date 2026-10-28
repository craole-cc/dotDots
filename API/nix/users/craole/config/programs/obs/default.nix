{
  lib,
  user,
  ...
}: let
  app = "obs-studio";
  inherit (lib.lists) elem;
  inherit (user.applications) allowed;
  isAllowed = elem app allowed;
in {
  programs.${app}.enable = isAllowed;
  imports = [];
}
