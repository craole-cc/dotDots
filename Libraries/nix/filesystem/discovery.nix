{
  _,
  lib,
  ...
}: let
  inherit (_.content.empty) isNotEmpty;
  inherit (lib.filesystem) listFilesRecursive packagesFromDirectoryRecursive;
  inherit (lib.strings) hasSuffix;
  inherit (lib.lists) filter map elem;

  exports = {
    internal = {
      inherit
        listRecursively
        listNix
        listNixModules
        listPackagesRecursively
        ;
    };
    external = {
      inherit (exports.internal) listNixModules;
      listFilesRecursively = listRecursively;
      listNixFiles = listNix;
      listNixPackagesRecursively = listPackagesRecursively;
    };
  };
  /**
  List all files under a directory, recursively.

  # Type
  ```nix
  listRecursively :: path -> [path]
  ```
  */
  listRecursively = path: listFilesRecursive path;

  /**
  Build a recursive package attrset from a directory using `callPackage`.

  # Type
  ```nix
  listPackagesRecursively :: AttrSet -> path -> AttrSet
  ```
  */
  listPackagesRecursively = pkgs: path:
    packagesFromDirectoryRecursive {
      inherit (pkgs) callPackage;
      directory = path;
    };

  defaultFilesToExclude = [
    "default.nix"
    "flake.nix"
    "shell.nix"
    "paths.nix"
  ];

  defaultFoldersToExclude = [
    "review"
    "tmp"
    "temp"
    "archive"
  ];

  /**
  List all `.nix` files under a directory, excluding common boilerplate
  files and directories.

  # Type
  ```nix
  listNixModules :: path -> [path]
  ```
  */
  listNixModules = path: let
    isNixFile = file: hasSuffix ".nix" (baseNameOf file);
    isExcludedFile = file: elem (baseNameOf file) defaultFilesToExclude;
    isExcludedFolder = file: elem (dirOf file) defaultFoldersToExclude;
    files = listFilesRecursive path;
  in
    filter
    (file: isNixFile file && !isExcludedFile file && !isExcludedFolder file)
    files;

  /**
  List all `.nix` file paths under a directory as strings.

  # Type
  ```nix
  listNix :: path -> [string]
  ```
  */
  listNix = path:
    filter isNotEmpty (map toString (listFilesRecursive path));
in
  exports // {_rootAliases = exports;}
