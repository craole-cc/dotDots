{lib, ...}: let
  # ========================
  # IMPORTS
  # ========================
  inherit
    (lib.filesystem)
    listFilesRecursive
    packagesFromDirectoryRecursive
    ;
  # inherit (lib.trivial) functionArgs;
  inherit (lib.strings) hasSuffix;
  inherit (lib.lists) filter map elem;
  inherit
    (builtins)
    baseNameOf
    dirOf
    toString
    ;

  # List all files under a dir, recursively.
  listFilesRecursively = path: listFilesRecursive path;

  # Turn a directory tree of packages into an attrset and call them.
  # This mirrors lib.filesystem.packagesFromDirectoryRecursive. [web:1179]
  listNixPackagesRecursively = pkgs: path: let
    pkgsAttrset = packagesFromDirectoryRecursive {
      inherit (pkgs) callPackage;
      directory = path;
    };
  in
    pkgsAttrset;

  # List nix module paths under a dir, excluding some files/folders.
  listNixModules = path: let
    filesToExclude = [
      "default.nix"
      "flake.nix"
      "shell.nix"
      "paths.nix"
    ];

    foldersToExclude = [
      "review"
      "tmp"
      "temp"
      "archive"
    ];

    isNixFile = file: hasSuffix ".nix" (baseNameOf file);
    isExcludedFile = file: elem (baseNameOf file) filesToExclude;
    isExcludedFolder = file: elem (dirOf file) foldersToExclude;

    files = listFilesRecursive path;
    sansNonNix = filter isNixFile files;
    sansExcludedFiles = filter (file: !isExcludedFile file) sansNonNix;
    sansExcludedDirs = filter (file: !isExcludedFolder file) sansExcludedFiles;
  in
    sansExcludedDirs;

  # Simple “all .nix files” listing
  listNix = path: let
    files = listFilesRecursive path;
  in
    filter (hasSuffix ".nix") (map toString files);

  # Import all nix modules found by listNixModules

  # Import all subdirectories of `dir` as modules, keyed by name.

  # Import all *.nix files (except default.nix) in `dir` as a list of modules.
in {
  inherit
    listFilesRecursively
    listNix
    listNixModules
    listNixPackagesRecursively
    ;
}
