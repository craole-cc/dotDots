{
  user,
  lib,
  ...
}: let
  app = "direnv";
  inherit (lib.lists) elem;
  inherit (user.applications) allowed;
  isAllowed = elem app allowed;
in {
  programs.${app} = {
    enable = isAllowed;
    silent = true;
    mise.enable = true;
  };
}
