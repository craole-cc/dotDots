args: let
  inherit (import ./environment args) description env shellHook;
  inherit
    (import ./package.nix (args // {inherit description env;}))
    # apps
    packages
    # paths
    # runtimes
    ;
in {inherit description env packages shellHook;}
