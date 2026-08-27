{
  bootstrap ? {},
  config ? {
    names = let
      explicit = bootstrap.names or {};
      implicit = {
        top = explicit.top or "dots";
        lib = explicit.lib or "lix";
      };
    in
      implicit // explicit;
    paths = let
      explicit = bootstrap.paths or {};
      implicit = {
        flake = (explicit.flake or {}) // {store = ../../.;};
        libraries = (explicit.libraries or {}) // {store = ./.;};
      };
    in
      explicit // implicit;
    flattenLibraries = bootstrap.flattenLibraries or false;
    testLibraries = bootstrap.testLibraries or false;
    collisionStrategy = bootstrap.collisionStrategy or "warn";
    exclusions = {
      dirs = [
        "review"
        "archive"
        "internal"
        "imports"
        "data"
        "test"
        "tmp"
        "temp"
        "wip"
        "deprecated"
        "experimental"
        "backup"
      ];
      files = [
        "default.nix"
        "flake.nix"
      ];
      patterns = [
        " copy.nix"
        ".test.nix"
        ".spec.nix"
        ".bak.nix"
        ".old.nix"
      ];
    };
  },
  collisionStrategy ? config.collisionStrategy,
  excludedDirs ? config.exclusions.directories,
  excludedFiles ? config.exclusions.files,
  excludedPatterns ? config.exclusions.patterns,
  flake ? null,
  lib ? null,
  name ? config.names.lib or null,
  names ? config.names or null,
  paths ? config.paths or null,
  rootAliases ? config.flattenLibraries,
  runTests ? config.testLibraries,
}: let
  defaults = {
    names = {
      top = "dots";
      lib = "lix";
    };
    collisionStrategy = "warn";
    paths = {
      flake.store = ../../.;
      libraries.store = ./.;
    };
    exclusions = {
      dirs = [
        "review"
        "archive"
        "internal"
        "imports"
        "data"
        "test"
        "tmp"
        "temp"
        "wip"
        "deprecated"
        "experimental"
        "backup"
      ];
      files = [
        "default.nix"
        "flake.nix"
      ];
      patterns = [
        " copy.nix"
        ".test.nix"
        ".spec.nix"
        ".bak.nix"
        ".old.nix"
      ];
    };
  };

  inherit (builtins) attrNames isAttrs mapAttrs;
  mergeAttrs =
    bootstrap.mergeAttrs or(
      set1: set2:
        if isAttrs set1 && isAttrs set2
        then
          (mapAttrs (key: value:
            if set1 ? ${key}
            then mergeAttrs set1.${key} value
            else value)
          set2)
          // removeAttrs set1 (attrNames set2)
        else set2
    );

  paths' =
    if paths != null
    then paths
    else defaults.paths;

  flake' =
    if flake != null
    then flake
    else if (builtins ? getFlake)
    then let
      inherit (builtins) getFlake pathExists;
      inherit (paths') src;
    in
      if pathExists (toString src + "/flake.nix")
      then getFlake (toString src)
      else {}
    else {};

  lib' =
    if lib != null
    then lib
    else if flake' ? inputs && flake'.inputs ? nixpkgs
    then flake'.inputs.nixpkgs.lib
    else import <nixpkgs/lib>;
  inherit (lib') optionalAttrs;
in
  import ./internal {
    collisionStrategy =
      if collisionStrategy != null
      then collisionStrategy
      else defaults.collisionStrategy;

    exclusions = let
      inherit (lib'.lists) uniqueStrings;
      mk = kind: base: uniqueStrings (defaults.exclusions.${kind} ++ base);
    in {
      dirs = mk "dirs" excludedDirs;
      files = mk "files" excludedFiles;
      patterns = mk "patterns" excludedPatterns;
    };

    flake = flake';
    lib = lib';

    names =
      defaults.names
      // (optionalAttrs (isAttrs names) names)
      // (optionalAttrs (name != null) {lib = name;});

    paths = paths';

    inherit rootAliases runTests;
  }
