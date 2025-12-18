{
  user,
  lib,
  ...
}: let
  app = "mpv";
  inherit (lib.lists) elem;
  inherit (user.applications) allowed;
  isAllowed = elem app allowed;
in {
  programs.${app} = {enable = isAllowed;} // import ./settings.nix;
}
