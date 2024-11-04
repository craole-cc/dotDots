{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with types;
with filesystem;
let
  mod = "path";
  cfg = config.DOTS.Libraries.${mod};
in
{
  options.DOTS.Libraries.${mod} = with cfg; {

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

          # sansExcludedFiles = filter (file: file == path || (!elem (baseNameOf file) excludedFiles)) files;
          # sansExcludedFiles = filter (file: !isExcludedFile file) files;
          # sansExcludedFiles = filter (file: file == path || (!elem (baseNameOf file) excludedFiles)) files;

          # sansLoaders = filter isLoader sansNonNix;
          # sansExcludedFolders = filter (folder: !isExcluded folder) sansLoaders;

          # isExcluded = file: any (folder: hasPrefix folder file) excludeFolders;
          filesSansExcludedFolders = filter (folder: !isExcluded folder) filesSansLoaders;

          gitignorePath = "${path}/.gitignore";
          gitignoreContents = builtins.readFile gitignorePath;
          filteredFiles = builtins.filterSource (f: builtins.elem f) files;
          filteredFilesWithoutExcluded = filter (file: !isExcluded file) filteredFiles;
          filesOrig = filter (file: file == path || (!elem (baseNameOf file) loaders)) (
            listFilesRecursive path
          );
        in
        modules;
    };

    listNix = mkOption {
      description = "List all nix paths in a directory.";
      example = ''listRecursively "path/to/directory"'';
      default = path: filter (hasSuffix ".nix") (map toString (listFilesRecursive path));
      # default = path: filter (hasSuffix ".nix") (filesystem.listFilesRecursive path);
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
  };
}
