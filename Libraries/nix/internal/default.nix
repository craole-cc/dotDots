{
  lib,
  path,
  name,
  collisionStrategy,
  runTests,
  rootAliases,
  excludedDirs,
  excludedFiles,
  excludedPatterns,
}: let
  basePath = path + "/Libraries/nix";
  lib' = import ./bootstrap.nix {inherit lib path;};
  handle = import ./collisions.nix {inherit lib' collisionStrategy;};

  inherit (lib'.fixedPoints) makeExtensible;

  library = makeExtensible (
    self: let
      safeLib = handle self;
      scan = import ./scan.nix {
        inherit
          basePath
          excludedDirs
          excludedFiles
          excludedPatterns
          lib'
          path
          runTests
          ;
        env = import ./env.nix {
          inherit
            lib'
            path
            name
            self
            safeLib
            ;
        };
      };
      results = scan basePath [];
    in
      results.modules
      // {
        __rootAliases = results.rootAliases;
      }
  );
in {
  ${name} = import ./assemble.nix {
    inherit
      collisionStrategy
      lib'
      library
      path
      rootAliases
      ;
  };
}
