{
  collisionStrategy,
  exclusions,
  flake,
  lib,
  names,
  paths,
  rootAliases,
  runTests,
}: {
  ${names.lib} = import ./assemble.nix {
    inherit collisionStrategy flake lib paths rootAliases;
    library = lib.fixedPoints.makeExtensible (
      self: let
        safe = import ./collisions.nix {inherit lib collisionStrategy;} self;
        scan = import ./scan.nix {
          inherit paths exclusions lib runTests;
          env = import ./env.nix {
            inherit flake lib names paths safe self;
          };
        };
        results = scan paths.libraries [];
      in
        results.modules // {__rootAliases = results.rootAliases;}
    );
  };
}
