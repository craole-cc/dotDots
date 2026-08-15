args: let
  inherit
    (import ./common/environment args)
    description
    env
    shellHook
    ;
  inherit
    (
      import ./common/packages
      (args // {inherit description env;})
    )
    # apps
    packages
    # paths
    # runtimes
    ;
in {inherit description env packages shellHook;}
