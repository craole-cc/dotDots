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
  inherit (lib'.attrsets) attrNames;
  inherit (lib'.lists) elem filter;
  inherit (lib'.debug) trace;

  library = makeExtensible (self: let
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
      env = import ./env.nix {inherit lib' path name self safeLib;};
    };
    results = scan basePath [];
  in
    if !rootAliases
    then results.modules
    else let
      rootAliasNames = attrNames results.rootAliases;
      moduleTopLevelNames = attrNames results.modules;
      collisions = filter (n: elem n moduleTopLevelNames) rootAliasNames;
    in
      if collisions == []
      then results.modules // results.rootAliases
      else if collisionStrategy == "error"
      then throw "Root aliases collide with modules: ${toString collisions}"
      else if collisionStrategy == "warn"
      then
        trace "WARNING: Root aliases override modules for: ${toString collisions}"
        (results.modules // results.rootAliases)
      else results.modules // results.rootAliases);
in {${name} = import ./assemble.nix {inherit lib' library path;};}
