{
  collisionStrategy ? null,
  excludedDirs ? [],
  excludedFiles ? [],
  excludedPatterns ? [],
  flake ? null,
  lib ? null,
  name ? null,
  names ? {},
  paths ? {},
  rootAliases ? false,
  runTests ? true,
}: let
  defaults = {
    names = {
      top = "dots";
      lib = "lix";
    };
    collisionStrategy = "warn";
    paths = {
      src = ../../.;
      libraries = ./.;
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

  paths' = defaults.paths // paths;

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
in
  import ./internal {
    collisionStrategy =
      if collisionStrategy != null
      then collisionStrategy
      else defaults.collisionStrategy;

    exclusions = let
      inherit (lib'.lists) uniqueStrings;
      mk = domain: explicit: uniqueStrings (defaults.exclusions.${domain} ++ explicit);
    in {
      dirs = mk "dirs" excludedDirs;
      files = mk "files" excludedFiles;
      patterns = mk "patterns" excludedPatterns;
    };

    flake = flake';
    lib = lib';

    names = let
      inherit (lib'.attrsets) optionalAttrs;
    in
      defaults.names // (optionalAttrs (name != null) {lib = name;}) // names;

    paths = paths';

    inherit rootAliases runTests;
  }
