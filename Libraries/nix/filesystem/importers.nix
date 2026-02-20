{lib, ...}: let
  inherit
    (lib.attrsets)
    attrValues
    listToAttrs
    attrNames
    filterAttrs
    ;
  inherit (lib.trivial) functionArgs;
  inherit (lib.filesystem) listFilesRecursive;
  inherit (lib.strings) hasSuffix hasInfix;
  inherit
    (lib.lists)
    any
    elem
    filter
    flatten
    foldl'
    map
    ;
  inherit
    (builtins)
    baseNameOf
    readDir
    toString
    ;

  # -- Shared exclusion config ──────────────────────────────────────────────
  nixFilesToExclude = [
    "default.nix"
    "flake.nix"
    "shell.nix"
    "paths.nix"
  ];

  foldersToExclude = [
    "archives"
    "review"
    "temp"
    "tmp"
  ];

  # True if any path segment of `file` is an excluded folder name.
  # Handles arbitrary nesting (e.g. archives/old/module.nix).
  isUnderExcludedFolder = file:
    any (
      folder:
        hasInfix "/${folder}/" (toString file)
        || hasSuffix "/${folder}" (toString file)
    )
    foldersToExclude;

  # -- listNixModules ───────────────────────────────────────────────────────
  listNixModules = path: let
    isNixFile = file: hasSuffix ".nix" (baseNameOf file);
    isExcludedFile = file: elem (baseNameOf file) nixFilesToExclude;

    files = listFilesRecursive path;
    sansNonNix = filter isNixFile files;
    sansExcludedFiles = filter (f: !isExcludedFile f) sansNonNix;
    sansExcludedDirs = filter (f: !isUnderExcludedFolder f) sansExcludedFiles;
  in
    sansExcludedDirs;

  # -- importNixModules ─────────────────────────────────────────────────────
  importNixModules = path:
    map (modulePath: import modulePath) (listNixModules path);

  # -- importAttrs / importNames / importValues ─────────────────────────────
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

  # -- importAll ────────────────────────────────────────────────────────────
  importAll = dir: let
    entries = readDir dir;

    nixFiles = filter (
      name:
        entries.${name}
        == "regular"
        && hasSuffix ".nix" name
        && name != "default.nix"
    ) (attrNames entries);

    #? Excluded folder names are pruned here — no recursion into them at all.
    subDirs = filter (
      name:
        entries.${name}
        == "directory"
        && !(elem name foldersToExclude)
    ) (attrNames entries);

    fileImports = map (name: import (dir + "/${name}")) nixFiles;

    dirImports =
      map (
        name: let
          subPath = dir + "/${name}";
          subEntries = readDir subPath;
          hasDefault =
            subEntries ? "default.nix"
            && subEntries."default.nix" == "regular";
        in
          if hasDefault
          then import (subPath + "/default.nix")
          else importAll subPath
      )
      subDirs;

    flatDirImports = flatten dirImports;
  in
    fileImports ++ flatDirImports;

  # -- importAllMerged ──────────────────────────────────────────────────────
  importAllMerged = dir: args: let
    entries = readDir dir;
    nixFiles = filter (
      name:
        entries.${name}
        == "regular"
        && hasSuffix ".nix" name
        && name != "default.nix"
    ) (attrNames entries);
    imported = map (name: import (dir + "/${name}") args) nixFiles;
  in
    foldl' (acc: mod: acc // mod) {} imported;

  # -- importWithArgs ───────────────────────────────────────────────────────
  importWithArgs = {
    path,
    args ? {},
  }: let
    required = attrNames (functionArgs (import path));
    filtered = filterAttrs (name: _: elem name required) args;
  in
    import path filtered;

  # -- Exports ──────────────────────────────────────────────────────────────
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
