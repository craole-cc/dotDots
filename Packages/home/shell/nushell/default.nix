{
  user,
  lix,
  pkgs,
  lib,
  ...
}: let
  app = "nushell";
  inherit (lix.lists.predicates) isIn;
  inherit (lib.lists) optional;
  inherit (lib.modules) mkMerge;

  isAllowed = isIn app (
    (user.shells or [])
    ++ (user.applications.allowed or [])
    ++ (optional ((user.interface.shell or null) != null) user.interface.shell)
  );
in {
  programs.${app} = mkMerge [
    {enable = isAllowed;}
    # (import ./plugins.nix {inherit pkgs;})
    (import ./settings.nix)
  ];

  home.packages = with pkgs; [
    nufmt
    nu_scripts
  ];
}
