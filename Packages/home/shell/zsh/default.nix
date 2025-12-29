{
  user,
  lix,
  ...
}: let
  app = "zsh";
  inherit (lix.lists.predicates) isIn;
  isAllowed = isIn app (
    (user.shells or [])
    ++ user.applications.allowed or []
    ++ user.interface.shell or null
  );
in {
  programs.${app} =
    {enable = isAllowed;}
    // import ./settings.nix;
}
