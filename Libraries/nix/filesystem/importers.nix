{_, ...}: let
  inherit (_.attrsets.access) attrNames attrValues;
  inherit (_.attrsets.construction) listToAttrs;
  inherit (_.attrsets.transformation) filterAttrs functionArgs;
  inherit (_.filesystem.meta) listNixModules;
  inherit (_.filesystem.resolution) mkPath;
  inherit (_.filesystem.traversal) readDir;
  inherit (_.lists.aggregation) foldl';
  inherit (_.lists.transformation) flatten;
  inherit (_.lists.predicates) elem;
  inherit (_.lists.selection) filter;
  inherit (_.strings.access) substring stringLength;
  inherit (_.strings.predicates) hasSuffix;

  exports = {
    inherit
      importAll
      importAllMerged
      importAllPaths
      importAttrs
      importRegistry
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

  # -- helpers

  /**
    Return the names of all regular `.nix` files (excluding `default.nix`)
    in `entries` (the result of `readDir dir`).

    # Type
  ```nix
    nixFilesIn :: AttrSet -> [string]
  ```
  */
  nixFilesIn = entries:
    filter
    (name: entries.${name} == "regular" && hasSuffix ".nix" name && name != "default.nix")
    (attrNames entries);

  /**
    Return the names of all subdirectories in `entries` that are not in
    `foldersToExclude`.

    # Type
  ```nix
    subDirsIn :: AttrSet -> [string]
  ```
  */
  subDirsIn = entries:
    filter
    (name: entries.${name} == "directory" && !(elem name foldersToExclude))
    (attrNames entries);

  # -- importNixModules

  /**
    Import all `.nix` modules found by `meta.listNixModules`.

    Delegates listing entirely to `meta` - no duplicate exclusion logic here.

    # Type
  ```nix
    importNixModules :: path -> [any]
  ```
  */
  importNixModules = path: map import (listNixModules path);

  # -- importAttrs / importNames / importValues

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

  # -- importAll / importAllPaths

  /**
    Recursively traverse `dir`, collecting either imported values or paths for
    all `.nix` files (except `default.nix`) and subdirectories.

    Subdirectories with a `default.nix` are treated as a unit; others are
    recursed into. Excluded folder names are pruned entirely.

    `collect` determines what is produced per item:
      - `import path` for `importAll`
      - `path`        for `importAllPaths`

    # Type
  ```nix
    traverseDir :: (path -> any) -> (path -> [any]) -> path -> [any]
  ```
  */
  traverseDir = collect: recurse: dir: let
    entries = readDir dir;

    fileResults = map (name: collect (dir + "/${name}")) (nixFilesIn entries);

    dirResults =
      map (
        name: let
          subPath = dir + "/${name}";
          subEntries = readDir subPath;
          hasDefault = subEntries ? "default.nix" && subEntries."default.nix" == "regular";
        in
          if hasDefault
          then collect (subPath + "/default.nix")
          else recurse subPath
      )
      (subDirsIn entries);
  in
    fileResults ++ flatten dirResults;

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
  importAll = traverseDir import importAll;

  /**
    Return paths of all `.nix` files (except `default.nix`) and
    subdirectories with `default.nix` under `dir`, without importing them.

    Prefer this over `importAll` when used in NixOS `imports` - paths give
    better error traces and enable `disabledModules` to work correctly.

    # Type
  ```nix
    importAllPaths :: path -> [path]
  ```
  */
  importAllPaths = traverseDir (p: p) importAllPaths;

  # -- importAllMerged

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
  in
    foldl' (acc: mod: acc // mod) {} (map (name: import (dir + "/${name}") args) (nixFilesIn entries));

  importRegistry = {
    root,
    stems ? ["data"],
    recursive ? false,
    args ? {},
  }: let
    path = mkPath {inherit root stems;};
    entries = readDir path;

    stemOf = name: substring 0 (stringLength name - 4) name;

    direct = listToAttrs (
      map (name: {
        name = stemOf name;
        value = importWithArgs {
          path = path + "/${name}";
          inherit args;
        };
      })
      (nixFilesIn entries)
    );
  in
    if recursive
    then
      direct
      // foldl'
      (acc: name:
        acc
        // importRegistry {
          inherit root args recursive;
          stems = stems ++ [name];
        })
      {}
      (subDirsIn entries)
    else direct;

  # -- importWithArgs

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
  exports // {__rootAliases = exports;}
