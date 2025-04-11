{
  config,
  lib,
  pkgs,
  ...
}:
let
  #| Module Parts
  top = "DOTS";
  dom = "lib";
  mod = "path";
  alt = "dib";

  #| Native Imports
  inherit (lib.options) mkOption;
  inherit (lib.filesystem) listFilesRecursive packagesFromDirectoryRecursive;
  inherit (lib.strings) hasSuffix;
  inherit (lib.lists) filter map elem;

  #| Module Imports
  cfg = config.${top}.${dom}.${mod};

  #| Module Options
  listFilesRecursively = mkOption {
    description = "List all nix paths in a directory.";
    example = ''listRecursively "path/to/directory"'';
    default = path: listFilesRecursive path;
  };

  listNixPackagesRecursively = mkOption {
    description = "List all nix paths in a directory.";
    example = ''listRecursively "path/to/directory"'';
    default =
      path:
      let
        packages = packagesFromDirectoryRecursive path;
      in
      pkgs.callPackages packages;
  };

  listNixModules = mkOption {
    description = "List all nix paths in a directory.";
    example = ''listNix "path/to/directory"'';
    default =
      path:
      let
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
        ];

        #> File Types
        isNixFile = file: hasSuffix ".nix" (baseNameOf file);
        isExcludedFile = file: elem (baseNameOf file) filesToExclude;
        isExcludedFolder = file: elem (dirOf file) foldersToExclude;

        #> Files
        files = listFilesRecursive path;
        sansNonNix = filter isNixFile files;
        sansExcludedFiles = filter (file: !isExcludedFile file) sansNonNix;
        sansExcludedFolders = filter (folder: !isExcludedFolder folder) sansExcludedFiles;

        modules = sansExcludedFolders;
      in
      modules;
  };

  listNix = mkOption {
    description = "List all nix paths in a directory.";
    example = ''listRecursively "path/to/directory"'';
    default = path: filter (hasSuffix ".nix") (map toString (listFilesRecursive path));
  };

  importNixModules = mkOption {
    description = "List all nix paths in a directory.";
    example = ''listNix "path/to/directory"'';
    default =
      path:
      let
        modules = cfg.listNixModules path;
      in
      map (module: import module) modules;
  };

  #| Module Exports
  exports = {
    inherit
      listFilesRecursively
      listNixPackagesRecursively
      listNixModules
      listNix
      importNixModules
      ;
  };
in
{
  options = {
    ${top}.${dom}.${mod} = exports;
    ${alt} = exports;
  };
}
