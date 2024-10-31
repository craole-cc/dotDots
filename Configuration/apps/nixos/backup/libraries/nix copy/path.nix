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
  cfg = config.dots.lib.${mod};
in
{
  options.dots.lib.${mod} = with cfg; {

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
      default = path: filter (hasSuffix ".nix") (map toString (filesystem.listFilesRecursive path));
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

    locateParentByChildren = mkOption {
      description = "Find the absolute path of the parent directory of an item or a list of children.";
      example = ''locateParentByChildren "src" ==> "/path/to/project"'';
      default =
        children:
        let
          search = child: filesystem.locateDominatingFile child ./.;
          result = filter (path: path != null) (map search (toList children));
          nullOrLocation = if length result > 0 then (head result).path else null;
        in
        nullOrLocation;
    };

    locateParentByName = mkOption {
      description = "Find the absolute path of a specific path (by name) in a parent directory.";
      example = ''locateParentByName "src" ==> "/path/to/project/src"'';
      default =
        name:
        let
          result = cfg.locateParentByChildren name;
          nullOrLocation = if result != null then result + "/${name}" else null;
        in
        nullOrLocation;
    };

    locateParentByNameOrChildren = mkOption {
      description = "Find the absolute path of a parent directory by name, falling back to files or a list of files for search.";
      example = ''locateParentByNameOrChildren "src" [".git" ".gitignore" ".flake.nix"] ==> "/path/to/project/root"'';
      default =
        name: children:
        let
          byName = cfg.parentByName name;
          byChildren = cfg.parentByChildren children;
          nullOrLocation = if byName != null then byName else byChildren;
        in
        nullOrLocation;
    };

    locateProjectRoot = mkOption {
      description = "Find the absolute path of the project root.";
      example = ''locateProjectRoot ==> "/path/to/project/root"'';
      default =
        let
          nullOrLocation = cfg.locateParentByChildren [
            ".git"
            ".gitignore"
            ".flake.nix"
            ".envrc"
            ".cargo.lock"
            "package.json"
            "Cargo.lock"
            "Cargo.toml"
          ];
        in
        nullOrLocation;
    };
  };
}
