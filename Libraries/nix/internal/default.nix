{
  collisionStrategy,
  exclusions,
  flake,
  lib,
  names,
  paths,
  rootAliases,
  runTests,
}: let
  handleCollisions = import ./collisions.nix {inherit lib collisionStrategy;};
  result = import ./assemble.nix {
    inherit
      handleCollisions
      lib
      paths
      rootAliases
      ;
    library = lib.fixedPoints.makeExtensible (
      self: let
        safe = handleCollisions {
          msg = "Custom library has collisions with nixpkgs lib";
          overrides = self;
        };
        scan = import ./scan.nix {
          inherit
            exclusions
            paths
            lib
            runTests
            ;
          env = import ./env.nix {
            inherit
              flake
              lib
              names
              paths
              safe
              self
              ;
          };
        };
        results = scan paths.libraries [];
      in
        results.modules // {__rootAliases = results.rootAliases;}
    );
  };
in {${names.lib} = result;}
