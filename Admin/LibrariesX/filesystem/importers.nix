{lib, ...}: let
  inherit
    (lib.attrsets)
    attrValues
    listToAttrs
    attrNames
    ;
  inherit
    (lib.filesystem)
    listFilesRecursive
    ;
  # inherit (lib.trivial) functionArgs;
  inherit (lib.strings) hasSuffix;
  inherit (lib.lists) filter map elem;
  inherit
    (builtins)
    baseNameOf
    dirOf
    readDir
    ;

  # List all files under a dir, recursively.

  # Turn a directory tree of packages into an attrset and call them.
  # This mirrors lib.filesystem.packagesFromDirectoryRecursive.

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

  # Import all nix modules found by listNixModules
  importNixModules = path: let
    modules = listNixModules path;
  in
    map (modulePath: import modulePath) modules;

  # Import all subdirectories of `dir` as modules, keyed by name.
  importAttrs = dir: let
    entries = readDir dir;
    dirNames = filter (name: entries.${name} == "directory") (attrNames entries);
  in
    listToAttrs (
      map (name: {
        inherit name;
        value = import (dir + "/${name}");
      })
      dirNames
    );

  importNames = dir: attrNames (importAttrs dir);
  importValues = dir: attrValues (importAttrs dir);

  # Import all *.nix files (except default.nix) in `dir` as a list of modules.
  # If a subdirectory contains a default.nix, import that instead of recursing.
  importAll = dir: let
    #> Get all paths in current directory
    entries = readDir dir;

    #> Get all .nix files in current directory (excluding default.nix)
    nixFiles = filter (
      name: entries.${name} == "regular" && hasSuffix ".nix" name && name != "default.nix"
    ) (attrNames entries);

    #> Get all subdirectories
    subDirs = filter (
      name: entries.${name} == "directory"
    ) (attrNames entries);

    #> Import .nix files from current directory
    fileImports = map (name: import (dir + "/${name}")) nixFiles;

    #> For each subdirectory, either import its default.nix or recurse
    dirImports =
      map (
        name: let
          subPath = dir + "/${name}";
          subEntries = readDir subPath;
          hasDefault = subEntries ? "default.nix" && subEntries."default.nix" == "regular";
        in
          if hasDefault
          then import (subPath + "/default.nix")
          else importAll subPath
      )
      subDirs;

    #> Flatten directory imports (they might be lists from recursion)
    flatDirImports = lib.flatten dirImports;
  in
    fileImports ++ flatDirImports;

  importWithArgs =
    # Imports a Nix module at 'path' with filtered and merged arguments.
    # Params:
    # - path: The path to the Nix module to import.
    # - args (optional): An attribute set of arguments to pass to the module.
    #
    # The function inspects the module's required arguments,
    # merges them with a set of common globally available attributes,
    # and only passes the arguments actually required by the module.
    #
    # This avoids passing extraneous or unexpected arguments and clarifies intent.
    {
      path,
      args ? {},
    }: let
      inherit (lib.attrsets) attrNames filterAttrs;
      inherit (lib.lists) elem;
      inherit (lib.trivial) functionArgs;

      #~@ Get the list of arguments the target module accepts
      required = attrNames (functionArgs (import path));

      #~@ Define the full set of arguments available to be injected
      provided = args;

      #~@ Filter the provided arguments to only include the ones the module requested
      filtered = filterAttrs (name: _: elem name required) provided;
    in
      import path filtered;

  importAllMerged = dir: args: let
    entries = readDir dir;
    nixFiles = filter (
      name: entries.${name} == "regular" && hasSuffix ".nix" name && name != "default.nix"
    ) (attrNames entries);
    imported = map (name: import (dir + "/${name}") args) nixFiles;
  in
    lib.foldl' (acc: mod: acc // mod) {} imported;

  exports = {
    inherit
      importAll
      importAllMerged
      importAttrs
      importNames
      importNixModules
      importValues
      importWithArgs
      ;
  };
in
  exports // {_rootAliases = exports;}
