{
  user,
  lib,
  host,
  pkgs,
  ...
}: let
  app = "mpv";
  inherit (lib.lists) elem;
  isAllowed = elem "video" (host.functionalities or []);
in {
  programs.${app} =
    {enable = isAllowed;}
    // import ./bindings.nix
    // import ./settings.nix {inherit pkgs;};
}
