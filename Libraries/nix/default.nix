{
  lib ? null,
  path,
  name ? "lix",
  collisionStrategy ? "warn",
  runTests ? true,
  rootAliases ? true,
  excludedDirs ? [
    "review"
    "archive"
    "internal"
    "imports"
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
(import ./internal) {
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
