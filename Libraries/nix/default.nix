{
  collisionStrategy ? defaults.collisionStrategy or "warn",
  excludedDirs ?
    defaults.exclusion.directories or [
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
    ],
  excludedFiles ?
    defaults.exclusion.files or [
      "default.nix"
      "flake.nix"
    ],
  excludedPatterns ?
    defaults.exclusion.patterns or [
      " copy.nix"
      ".test.nix"
      ".spec.nix"
      ".bak.nix"
      ".old.nix"
    ],
  flake ? null,
  lib ? null,
  name ? null,
  names ? {},
  defaults ? {},
  paths ? {
    src = ../../.;
    libraries = ./.;
  },
  rootAliases ? false,
  runTests ? true,
}: let
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
  inherit (lib') optionalAttrs uniqueStrings;
in
  import ./internal {
    collisionStrategy =
      if collisionStrategy != null
      then collisionStrategy
      else defaults.collisionStrategy;

    exclusions = let
      mk = domain: explicit: uniqueStrings (defaults.exclusions.${domain} ++ explicit);
    in {
      dirs = mk "dirs" excludedDirs;
      files = mk "files" excludedFiles;
      patterns = mk "patterns" excludedPatterns;
    };

    flake = flake';
    lib = lib';

    names =
      defaults.names
      // names
      // (optionalAttrs (name != null) {lib = name;});

    paths = paths';

    inherit rootAliases runTests;
  }
