{
  lix,
  host,
  ...
}: let
  app = "freetube";
  inherit (lix.lists.predicates) isIn;
  isAllowed = isIn "video" (host.functionalities or []);
in {
  programs.${app} =
    {
      enable = isAllowed;
    }
    // import ./settings.nix;
}
