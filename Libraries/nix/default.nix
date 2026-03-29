{
  lib ? null,
  path ? ../.,
  name ? "lix",
  collisionStrategy ? "warn",
  runTests ? true,
  excludedDirs ? [
    "review"
    "archive"
    "internal"
    "test"
    "tmp"
    "temp"
    "wip"
    "deprecated"
    "experimental"
    "backup"
  ],
  excludedFiles ? [
    "default.nix"
    "flake.nix"
  ],
  excludedPatterns ? [
    " copy.nix"
    ".test.nix"
    ".spec.nix"
    ".bak.nix"
    ".old.nix"
  ],
}: let
  i = import ./internal;

  lib' = i.bootstrap {inherit lib path;};
  handle = i.collisions {inherit lib' collisionStrategy;};

  inherit (lib'.fixedPoints) makeExtensible;
  inherit (lib'.attrsets) attrNames;
  inherit (lib'.lists) elem filter;
  inherit (lib'.debug) trace;

  customLib = makeExtensible (self: let
    safeLib = handle self;
    env = i.env {inherit lib' path name self safeLib;};
    scanDir = i.scanner {
      inherit lib' env path excludedDirs excludedFiles excludedPatterns runTests;
      scanBase = toString ./.;
    };

    results = scanDir ./. [];
    rootAliasNames = attrNames results.rootAliases;
    moduleTopLevelNames = attrNames results.modules;
    collisions = filter (n: elem n moduleTopLevelNames) rootAliasNames;

    library =
      if collisions == []
      then results.modules // results.rootAliases
      else if collisionStrategy == "error"
      then throw "Root aliases collide with modules: ${toString collisions}"
      else if collisionStrategy == "warn"
      then
        trace "WARNING: Root aliases override modules for: ${toString collisions}"
        (results.modules // results.rootAliases)
      else results.modules // results.rootAliases;
  in
    library);
in {${name} = i.assemble {inherit lib' customLib path;};}
