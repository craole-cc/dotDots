{
  lib ? null,
  path,
  name ? "lix",
  collisionStrategy ? "warn",
  runTests ? true,
  rootAliases ? false,
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
}:
(import ./internal).build {
  inherit
    lib
    path
    name
    collisionStrategy
    runTests
    rootAliases
    excludedDirs
    excludedFiles
    excludedPatterns
    ;
}
