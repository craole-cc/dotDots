{_, ...}: let
  inherit (_.attrsets.access) attrNames attrValues;
  inherit (_.attrsets.aggregation) recursiveUpdate;
  inherit (_.attrsets.construction) listToAttrs optionalAttrs;
  inherit (_.attrsets.transformation) filterAttrs functionArgs mapAttrs;
  inherit (_.debug.assertions) withContext;
  inherit (_.lists.construction) toList;
  inherit (_.filesystem.meta) listNixModules;
  inherit (_.filesystem.resolution) mkPath;
  inherit (_.filesystem.traversal) readDir;
  inherit (_.lists.aggregation) foldl';
  inherit (_.lists.predicates) elem any;
  inherit (_.lists.selection) filter;
  inherit (_.lists.transformation) flatten unique;
  inherit (_.strings.access) substring stringLength;
  inherit (_.strings.construction) concat;
  inherit (_.strings.predicates) hasSuffix hasPrefix;
  inherit (_.types.predicates) isAttrs isPath isString;

  exports = {
    inherit
      importAll
      importAllMerged
      importAllNamed
      importAllPaths
      importAttrs
      importRegistry
      importNames
      importNixModules
      importTree
      importValues
      ;
  };

  #> Directory names always excluded from every traversal in this file,
  #> regardless of any `exclude`/`excludePrefixes` passed at the call site.
  foldersToExclude = [
    "archives"
    "review"
    "temp"
    "tmp"
  ];

  #> Name prefixes excluded by default from every `importTree`-based walk
  #> (`importAllNamed`, `importAllMerged`). Pass `excludePrefixes = []` at
  #> the call site to disable, or a different list to use another convention.
  defaultExcludePrefixes = [
    "archive"
    "review"
  ];

  # -- helpers, shared by the non-importTree functions below

  /**
    Names of regular `.nix` files in `entries` (a `readDir` result),
    excluding `default.nix`.

    Internal helper shared by `traverseDir` and `importRegistry` - not
    exported on its own.

    # Inputs
    `entries`
    : the attrset returned by `readDir dir`

    # Type
    > nixFilesIn :: AttrSet -> [string]

    # Examples
    - nixFilesIn (readDir ./checks)

  ```nix
    [ "lint.nix" ]
  ```
  */
  nixFilesIn = entries:
    filter
    (name: entries.${name} == "regular" && hasSuffix ".nix" name && name != "default.nix")
    (attrNames entries);

  /**
    Names of subdirectories in `entries` (a `readDir` result) not listed in
    `foldersToExclude`.

    Internal helper shared by `traverseDir` and `importRegistry` - not
    exported on its own.

    # Inputs
    `entries`
    : the attrset returned by `readDir dir`

    # Type
    > subDirsIn :: AttrSet -> [string]

    # Examples
    - subDirsIn (readDir ./shells)

  ```nix
    [ "ai" "media" ]
  ```
  */
  subDirsIn = entries:
    filter
    (name: entries.${name} == "directory" && !(elem name foldersToExclude))
    (attrNames entries);

  # -- shared call primitive

  /**
    Import the module at `path` and call it with `args`.

    If the module's signature is an attrset pattern (e.g. `{cfg, pkgs, ...}:`),
    `args` is filtered down to only the keys it declares - avoiding
    "unexpected argument" errors for a closed (non-`...`) pattern. If the
    module takes a single plain parameter (e.g. `args:`) or no parameters
    mise can introspect, `functionArgs` returns `{}` and there is nothing
    safe to filter by - `args` is passed through whole instead, since a
    plain parameter can never throw "unexpected argument".

    # Inputs
    `args`
    : full candidate args attrset; filtered per-module only when the module
      declares an attrset pattern

    `path`
    : path to the `.nix` file to import and call

    # Type
    > importModuleFiltered :: AttrSet -> path -> any

    # Examples
    - importModuleFiltered { pkgs = pkgs; lix = lix; } ./shells/core/default.nix

  ```nix
    { description = "dotDots Dev Environment"; ... }
  ```
    (`core/default.nix` takes a single `args:` parameter, so `functionArgs`
    sees no declared keys and the full args attrset is passed through
    unfiltered.)
  */
  importModuleFiltered = args: path: let
    required = functionArgs (import path);
  in
    if required == {}
    then import path args
    else
      import path (
        filterAttrs (name: _: elem name (attrNames required)) args
      );

  # -- importNixModules

  /**
    Import every `.nix` module found by `meta.listNixModules` under `path`.

    Delegates listing entirely to `meta` - no duplicate exclusion logic here.

    # Inputs
    `path`
    : directory to search for `.nix` modules

    # Type
    > importNixModules :: path -> [any]

    # Examples
    - importNixModules ./checks

  ```nix
    [ {pkgs, ...}: {check = true;} ]
  ```
  */
  importNixModules = path: map import (listNixModules path);

  # -- importAttrs / importNames / importValues

  /**
    Import each immediate subdirectory of `dir` as a module, keyed by name.

    If `dir/default.nix` exists, its declared attrset is recursively merged
    underneath every imported entry - the entry remains the override, so a
    named record wins for keys it declares while inheriting unspecified keys
    from the directory declaration. An absent or empty directory declaration
    leaves the historical import behavior unchanged.

    This is a one-level (non-recursive) import with a merge-under-default
    semantic, distinct from `importAllNamed`'s leaf-per-default.nix semantic
    - use this when subdirectories share common defaults they can override,
    and `importAllNamed`/`importTree` when a `default.nix` should be treated
    as a self-contained unit instead.

    # Inputs
    `path` (bare path form)
    : directory whose immediate subdirectories are imported; `exclude`
      defaults to `[]`

    `path`, `exclude` (attrset form)
    : `path` as above; `exclude` is a list of subdirectory names to skip

    # Type
    > importAttrs :: path -> AttrSet
    > importAttrs :: { path :: path, exclude :: [string]? } -> AttrSet

    # Examples
    - importAttrs ./shells

  ```nix
    { ai = {description = "ai";}; media = {description = "media";}; }
  ```

    - importAttrs { path = ./shells; exclude = ["ai"]; }

  ```nix
    { media = {description = "media";}; }
  ```
  */
  importAttrs = args: let
    isAttrsArg = isAttrs args;

    dir = assert withContext {
      name = "importAttrs";
      context = "resolving `path`";
      assertion =
        if isAttrsArg
        then args ? path && isPath args.path
        else isPath args;
      message = "expected a path, or an attrset with a `path` value";
    };
      if isAttrsArg
      then args.path
      else args;

    exclude =
      if isAttrsArg
      then args.exclude or []
      else [];

    entries = readDir dir;
    dirNames = filter (name: entries.${name} == "directory" && !(elem name exclude)) (attrNames entries);
    domainDefault =
      if entries ? "default.nix"
      then import (dir + "/default.nix")
      else {};
  in
    listToAttrs (
      map (name: {
        inherit name;
        value = recursiveUpdate domainDefault (import (dir + "/${name}"));
      })
      dirNames
    );

  /**
    Names of all immediate subdirectories of `dir`.

    # Inputs
    `dir`
    : directory to list

    # Type
    > importNames :: path -> [string]

    # Examples
    - importNames ./shells

  ```nix
    [ "ai" "media" ]
  ```
  */
  importNames = dir: attrNames (importAttrs dir);

  /**
    Imported values of all immediate subdirectories of `dir`.

    # Inputs
    `dir`
    : directory to list

    # Type
    > importValues :: path -> [any]

    # Examples
    - importValues ./shells

  ```nix
    [ {description = "ai";} {description = "media";} ]
  ```
  */
  importValues = dir: attrValues (importAttrs dir);

  # -- importAll / importAllPaths

  /**
    Recursively traverse `dir`, collecting either imported values or paths
    for all `.nix` files (except `default.nix`) and subdirectories.

    Subdirectories with a `default.nix` are treated as a unit; others are
    recursed into. Excluded folder names (`foldersToExclude`) are pruned
    entirely. Internal primitive shared by `importAll`/`importAllPaths` -
    not exported on its own.

    # Inputs
    `collect`
    : `path -> any`, what to produce per matched item - `import path` for
      `importAll`, `path` itself for `importAllPaths`

    `recurse`
    : the calling function itself, threaded through for recursion

    `dir`
    : directory to traverse

    # Type
    > traverseDir :: (path -> any) -> (path -> [any]) -> path -> [any]

    # Examples
    - traverseDir import importAll ./shells

  ```nix
    [ {description = "ai";} {description = "media";} ]
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
    subdirectories under `dir`, returned as an unordered list.

    Subdirectories that contain a `default.nix` are imported as a unit;
    others are recursed into. Excluded folder names are pruned entirely.
    Prefer `importAllNamed`/`importTree` when you need results keyed by
    name rather than a flat list.

    # Inputs
    `dir`
    : directory to traverse

    # Type
    > importAll :: path -> [any]

    # Examples
    - importAll ./shells

  ```nix
    [ {description = "ai";} {description = "media";} ]
  ```
  */
  importAll = traverseDir import importAll;

  /**
    Paths (not imported values) of all `.nix` files (except `default.nix`)
    and default.nix-bearing subdirectories under `dir`.

    Prefer this over `importAll` when used in NixOS `imports` - paths give
    better error traces and let `disabledModules` work correctly.

    # Inputs
    `dir`
    : directory to traverse

    # Type
    > importAllPaths :: path -> [path]

    # Examples
    - importAllPaths ./shells

  ```nix
    [ /nix/store/.../shells/ai/default.nix /nix/store/.../shells/media/default.nix ]
  ```
  */
  importAllPaths = traverseDir (p: p) importAllPaths;

  # -- importTree (shared recursive named-traversal core)

  /**
    Recursively walk `dir`, keyed by name, calling every module with `args`
    (filtered to each module's own declared parameters via
    `importModuleFiltered`).

    At each level:
    - sibling `.nix` files (excluding `default.nix`) are imported and keyed
      by filename with the `.nix` suffix stripped;
    - a subdirectory containing `default.nix` is a leaf: only its
      `default.nix` is imported, keyed by the subdirectory's name;
    - a subdirectory without `default.nix` is recursed into if `recursive`
      is true, nested under the subdirectory's name; if `recursive` is
      false, such subdirectories are skipped entirely (only their
      default.nix-bearing siblings and this level's own files are kept).

    Throws if a file-derived key and a directory-derived key collide at the
    same level (e.g. `foo.nix` alongside a `foo/` containing `default.nix`)
    - silent last-write-wins was judged worse than a clear build-time error.

    `default.nix` is always excluded as a sibling file. `foldersToExclude`
    is always excluded, unconditionally. `exclude` is an additional list of
    exact names (files or directories) to skip at every level.
    `excludePrefixes` additionally skips any name starting with one of the
    given prefixes at every level, defaulting to `defaultExcludePrefixes`
    (`["archive" "review"]`) - pass `excludePrefixes = []` to disable.

    This is the shared core behind `importAllNamed` (`recursive = true`) and
    `importAllMerged` (`recursive = false`) - most call sites should prefer
    those two named entry points over calling `importTree` directly.

    # Inputs
    `dir`
    : directory to traverse

    `args`
    : args attrset to (filtered-)call every discovered module with,
      default `{}`

    `exclude`
    : exact file/directory names to skip at every level, default `[]`

    `excludePrefixes`
    : name prefixes to skip at every level, default `defaultExcludePrefixes`

    `recursive`
    : whether to descend into subdirectories that lack a `default.nix`,
      default `true`

    # Type
    > importTree :: { dir :: path, args :: AttrSet?, exclude :: [string]?, excludePrefixes :: [string]?, recursive :: bool? } -> AttrSet

    # Examples
    - importTree { dir = ./shells; args = { inherit pkgs; }; }

  ```nix
    { ai = {description = "ai";}; media = {description = "media";}; }
  ```

    - importTree { dir = ./checks; args = { inherit pkgs; }; recursive = false; }

  ```nix
    { lint = {check = true;}; }
  ```
  */
  importTree = {
    dir,
    args ? {},
    exclude ? [],
    excludePrefixes ? defaultExcludePrefixes,
    recursive ? true,
  }: let
    isExcluded = name:
      (elem name exclude)
      || (elem name foldersToExclude)
      || (any (prefix: hasPrefix prefix name) excludePrefixes);

    go = dir: let
      entries = readDir dir;

      fileNames =
        filter
        (name:
          (entries.${name} == "regular")
          && (hasSuffix ".nix" name)
          && (name != "default.nix")
          && !(isExcluded name))
        (attrNames entries);

      fileResults = listToAttrs (
        map (name: {
          name = substring 0 (stringLength name - 4) name;
          value = importModuleFiltered args (dir + "/${name}");
        })
        fileNames
      );

      dirNames =
        filter
        (name: entries.${name} == "directory" && !(isExcluded name))
        (attrNames entries);

      dirResults =
        map (
          name: let
            subPath = dir + "/${name}";
            subEntries = readDir subPath;
            hasDefault = subEntries ? "default.nix" && subEntries."default.nix" == "regular";
          in
            if hasDefault
            then {${name} = importModuleFiltered args (subPath + "/default.nix");}
            else optionalAttrs recursive {${name} = go subPath;}
        )
        dirNames;

      merged = foldl' (acc: sub: acc // sub) fileResults dirResults;

      fileKeys = attrNames fileResults;
      dirKeys = flatten (map attrNames dirResults);
      collisions = filter (k: elem k fileKeys) dirKeys;
    in
      assert withContext {
        name = "importTree";
        context = "checking for file/directory key collisions in ${toString dir}";
        assertion = collisions == [];
        message = "key(s) [${concat ", " collisions}] produced by both a .nix file and a subdirectory in the same folder - rename one";
      }; merged;
  in
    go dir;

  /**
    Recursively import `dir`, keyed by name, nested to mirror the folder
    tree. `importTree` with `recursive = true` (see `importTree` for full
    behavior, including the default.nix-as-leaf rule and collision check).

    # Inputs
    `dir`
    : directory to traverse

    `args`
    : args attrset to (filtered-)call every discovered module with,
      default `{}`

    `exclude`
    : exact file/directory names to skip at every level, default `[]`

    `excludePrefixes`
    : name prefixes to skip at every level, default `defaultExcludePrefixes`

    # Type
    > importAllNamed :: { dir :: path, args :: AttrSet?, exclude :: [string]?, excludePrefixes :: [string]? } -> AttrSet

    # Examples
    - importAllNamed { dir = ./shells; args = { inherit dots; }; }

  ```nix
    { ai = {description = "ai";}; media = {description = "media";}; }
  ```
  */
  importAllNamed = args: importTree (args // {recursive = true;});

  /**
    Import only the immediate `.nix` files and default.nix-bearing
    subdirectories of `dir` - no recursion into plain subdirectories.
    `importTree` with `recursive = false` (see `importTree` for full
    behavior, including the default.nix-as-leaf rule and collision check).

    # Inputs
    `dir`
    : directory to traverse

    `args`
    : args attrset to (filtered-)call every discovered module with,
      default `{}`

    `exclude`
    : exact file/directory names to skip, default `[]`

    `excludePrefixes`
    : name prefixes to skip, default `defaultExcludePrefixes`

    # Type
    > importAllMerged :: { dir :: path, args :: AttrSet?, exclude :: [string]?, excludePrefixes :: [string]? } -> AttrSet

    # Examples
    - importAllMerged { dir = ./checks; args = { inherit pkgs; }; }

  ```nix
    { lint = {check = true;}; }
  ```
  */
  importAllMerged = args: importTree (args // {recursive = false;});

  # -- importRegistry

  /**
    Import a directory of stem-organized `.nix` data files into a single
    registry attrset, tagging each entry with the stem(s) it was found
    under.

    # Inputs
    `value` (path or string form)
    : used directly as `root`; all other options take their defaults

    `value` (attrset form)
    : `root` - directory or string root to resolve via `mkPath`
      `stems` - path segments under `root` to descend through, default `["data"]`
      `recursive` - whether to also descend into subdirectories beyond `stems`, default `true`
      `extraArgs`/`args` - args attrset passed to `importModuleFiltered` for each data file

    # Type
    > importRegistry :: path | string | { root :: path | string, stems :: [string]?, recursive :: bool?, extraArgs :: AttrSet? } -> AttrSet

    # Examples
    - importRegistry ./data/tools.nix

  ```nix
    { alejandra = {categories = ["tools"]; ...}; shfmt = {categories = ["tools"]; ...}; }
  ```
  */
  importRegistry = value: let
    args =
      if isPath value || isString value
      then {root = value;}
      else if isAttrs value
      then value
      else
        assert withContext {
          name = "importRegistry";
          context = "validating importRegistry value";
          assertion = false;
          message = "expected `value` to be a path, string, or attrset";
        }; null;

    root = assert withContext {
      name = "importRegistry";
      context = concat " " ["resolving" "registry" "root"];
      assertion = args ? root && (isPath args.root || isString args.root);
      message = "expected `root` to be a path or string";
    };
      args.root;

    stems = args.stems or ["data"];
    recursive = args.recursive or true;
    extraArgs = args.extraArgs or (args.args or {});

    path = mkPath {inherit root stems;};
    entries = readDir path;

    stemOf = name: substring 0 (stringLength name - 4) name;

    direct = listToAttrs (
      map (name: let
        stem = stemOf name;
      in {
        name = stem;
        value = let
          raw = importModuleFiltered extraArgs (path + "/${name}");
        in
          mapAttrs (_: entry:
            entry
            // {
              categories = unique ((toList (entry.categories or [])) ++ [stem]);
            })
          raw;
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
          inherit root recursive extraArgs;
          stems = stems ++ [name];
        })
      {}
      (subDirsIn entries)
    else direct;
in
  exports // {__rootAliases = exports;}
