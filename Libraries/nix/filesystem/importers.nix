{lib, ...}: let
  inherit (lib.attrsets) attrValues listToAttrs attrNames filterAttrs;
  inherit (lib.filesystem) listFilesRecursive readDir;
  inherit (lib.strings) hasSuffix hasInfix;
  inherit (lib.lists) any elem filter flatten foldl' map;
  inherit (lib.trivial) functionArgs;

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

  #? True if any path segment of `file` is an excluded folder name.
  isUnderExcludedFolder = file:
    any
    (folder:
      hasInfix "/${folder}/" (toString file)
      || hasSuffix "/${folder}" (toString file))
    foldersToExclude;

  # -- listNixModules ───────────────────────────────────────────────────────

  /**
  List all `.nix` module paths under `path`, excluding boilerplate files
  and excluded directories (at any nesting depth).

  # Type
  ```nix
  listNixModules :: path -> [path]
  ```
  */
  listNixModules = path: let
    isNixFile = file: hasSuffix ".nix" (baseNameOf file);
    isExcludedFile = file: elem (baseNameOf file) nixFilesToExclude;

    files = listFilesRecursive path;
  in
    filter
    (f: isNixFile f && !isExcludedFile f && !isUnderExcludedFolder f)
    files;

  # -- importNixModules ─────────────────────────────────────────────────────

  /**
  Import all `.nix` modules found by `listNixModules`.

  # Type
  ```nix
  importNixModules :: path -> [any]
  ```
  */
  importNixModules = path: map import (listNixModules path);

  # -- importAttrs / importNames / importValues ─────────────────────────────

  /**
  Import each immediate subdirectory of `dir` as a module, keyed by name.

  # Type
  ```nix
  importAttrs :: path -> AttrSet
  ```
  */
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

  /**
  List names of all immediate subdirectories of `dir`.

  # Type
  ```nix
  importNames :: path -> [string]
  ```
  */
  importNames = dir: attrNames (importAttrs dir);

  /**
  Import values of all immediate subdirectories of `dir`.

  # Type
  ```nix
  importValues :: path -> [any]
  ```
  */
  importValues = dir: attrValues (importAttrs dir);

  # -- importAll ────────────────────────────────────────────────────────────

  /**
  Recursively import all `.nix` files (except `default.nix`) and
  subdirectories under `dir`. Subdirectories with a `default.nix` are
  imported as a unit; others are recursed into.

  Excluded folder names are pruned entirely — no recursion into them.

  # Type
  ```nix
  importAll :: path -> [any]
  ```
  */
  importAll = dir: let
    entries = readDir dir;

    nixFiles = filter (
      name:
        entries.${name}
        == "regular"
        && hasSuffix ".nix" name
        && name != "default.nix"
    ) (attrNames entries);

    subDirs = filter (
      name:
        entries.${name}
        == "directory"
        && !(elem name foldersToExclude)
    ) (attrNames entries);

    fileImports = map (name: import (dir + "/${name}")) nixFiles;

    dirImports = map (name: let
      subPath = dir + "/${name}";
      subEntries = readDir subPath;
      hasDefault =
        subEntries ? "default.nix"
        && subEntries."default.nix" == "regular";
    in
      if hasDefault
      then import (subPath + "/default.nix")
      else importAll subPath)
    subDirs;
  in
    fileImports ++ flatten dirImports;

  # -- importAllMerged ──────────────────────────────────────────────────────

  /**
  Import all `.nix` files (except `default.nix`) in `dir` (non-recursive),
  call each with `args`, and merge results into a single attrset.

  # Type
  ```nix
  importAllMerged :: path -> AttrSet -> AttrSet
  ```
  */
  importAllMerged = dir: args: let
    entries = readDir dir;
    nixFiles = filter (
      name:
        entries.${name}
        == "regular"
        && hasSuffix ".nix" name
        && name != "default.nix"
    ) (attrNames entries);
  in
    foldl'
    (acc: mod: acc // mod)
    {}
    (map (name: import (dir + "/${name}") args) nixFiles);

  # -- importWithArgs ───────────────────────────────────────────────────────

  /**
  Import the file at `path` and call it with only the subset of `args`
  that the module actually declares as parameters.

  # Type
  ```nix
  importWithArgs :: { path :: path, args :: AttrSet? } -> any
  ```
  */
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
