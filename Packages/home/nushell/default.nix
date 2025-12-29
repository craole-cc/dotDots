{
  user,
  lix,
  pkgs,
  ...
}: let
  app = "nushell";
  inherit (lix.lists.predicates) isIn;
  isAllowed = isIn app (
    (user.shells or [])
    ++ user.applications.allowed or []
    ++ [user.interface.shell or null]
  );
in {
  programs.${app} =
    {enable = isAllowed;}
    // import ./plugins.nix {inherit pkgs;}
    // import ./settings.nix;

  home.packages = with pkgs; [
    nufmt
    nu_scripts
  ];
}
