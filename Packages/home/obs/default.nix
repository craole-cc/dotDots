{
  user,
  lib,
  lix,
  host,
  pkgs,
  ...
}: let
  app = "obs-studio";
  inherit (lix.lists.predicates) isIn;
  isAllowed = isIn "video" (host.functionalities or []);
in {
  programs.${app} =
    {enable = isAllowed;}
    // import ./plugins.nix {inherit pkgs lib lix;};
}
