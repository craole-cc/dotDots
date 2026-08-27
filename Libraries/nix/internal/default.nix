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
  default = import ./assemble.nix {
    inherit handleCollisions lib paths rootAliases;
    library = lib.fixedPoints.makeExtensible (
      self: let
        safe = handleCollisions {
          msg = "Custom library has collisions with nixpkgs lib";
          overrides = self;
        };
        env = import ./env.nix {
          inherit flake lib names paths safe self;
        };
        scan = import ./scan.nix {
          inherit env exclusions paths lib runTests;
        };
        result = scan paths.libraries [];
      in
        result.modules // {__rootAliases = result.rootAliases;}
    );
  };
in {
  inherit default;
  ${names.lib} = default;
}
