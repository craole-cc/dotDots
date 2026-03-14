{
  _,
  lib,
  ...
}: let
  inherit (_.filesystem.meta) listNixModules;
  inherit (lib.attrsets) attrValues listToAttrs attrNames filterAttrs;
  inherit (lib.filesystem) readDir;
  inherit (lib.lists) elem filter flatten foldl' map;
  inherit (lib.strings) hasSuffix;
  inherit (lib.trivial) functionArgs;

  exports = {
    inherit
      importAll
      importAllMerged
      importAllPaths
      importAttrs
      importNames
      importNixModules
      importValues
      importWithArgs
      ;
  };

  foldersToExclude = [
    "archives"
    "review"
    "temp"
    "tmp"
  ];

  # -- importNixModules ───────────────────────────────────────────────────────

  /**
  Import all `.nix` modules found by `meta.listNixModules`.

  Delegates listing entirely to `meta` — no duplicate exclusion logic here.

  # Type
  ```nix
  importNixModules :: path -> [any]
  ```
  */
  importNixModules = path: map import (listNixModules path);

  # -- importAttrs / importNames / importValues ───────────────────────────────

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
    listToAttrs (map (name: {
        inherit name;
        value = import (dir + "/${name}");
      })
      dirNames);

  /**
  List the names of all immediate subdirectories of `dir`.

  # Type
  ```nix
  importNames :: path -> [string]
  ```
  */
  importNames = dir: attrNames (importAttrs dir);

  /**
  Import the values of all immediate subdirectories of `dir`.

  # Type
  ```nix
  importValues :: path -> [any]
  ```
  */
  importValues = dir: attrValues (importAttrs dir);

  # -- importAll ──────────────────────────────────────────────────────────────

  /**
  Recursively import all `.nix` files (except `default.nix`) and
  subdirectories under `dir`.

  Subdirectories that contain a `default.nix` are imported as a unit;
  others are recursed into. Excluded folder names are pruned entirely.

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
  in
    fileImports ++ flatten dirImports;

  # -- importAllMerged ────────────────────────────────────────────────────────

  /**
  Import all `.nix` files (except `default.nix`) in `dir` (non-recursive),
  call each with `args`, and deep-merge the results into a single attrset.

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

  # -- importAllPaths ─────────────────────────────────────────────────────────
  /**
  Return paths of all `.nix` files (except `default.nix`) and
  subdirectories with `default.nix` under `dir`, without importing them.

  Prefer this over `importAll` when used in NixOS `imports` — paths give
  better error traces and enable `disabledModules` to work correctly.

  # Type
  ```nix
  importAllPaths :: path -> [path]
  ```
  */
  importAllPaths = dir: let
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

    filePaths = map (name: dir + "/${name}") nixFiles;

    dirPaths =
      map (
        name: let
          subPath = dir + "/${name}";
          subEntries = readDir subPath;
          hasDefault =
            subEntries ? "default.nix"
            && subEntries."default.nix" == "regular";
        in
          if hasDefault
          then subPath
          else importAllPaths subPath
      )
      subDirs;
  in
    filePaths ++ flatten dirPaths;

  # -- importWithArgs ─────────────────────────────────────────────────────────

  /**
  Import the file at `path` and call it with only the subset of `args`
  that the module actually declares as parameters.

  Avoids "unexpected argument" errors when passing a broad args attrset
  to a module that only needs a few keys.

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
in
  exports // {_rootAliases = exports;}
