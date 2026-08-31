{
  _,
  projectPath,
  ...
}: let
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
  inherit (_.strings.construction) concat tokenize;
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

  relativeStem = root: path: let
    derived = {
      root = toString root + "/";
      path = toString path;
    };
  in
    filter (str: str != "") (
      tokenize "/" (
        if
          (substring 0 (stringLength derived.root) derived.path)
          == derived.root
        then substring (stringLength derived.root) (-1) derived.path
        else derived.path
      )
    );

  /**
  Names of regular `.nix` files in `entries` (a `readDir` result),
  excluding `default.nix`.
  */
  nixFilesIn = entries:
    filter (name: entries.${name} == "regular" && hasSuffix ".nix" name && name != "default.nix") (
      attrNames entries
    );

  /**
  Names of subdirectories in `entries` (a `readDir` result) not listed in
  `foldersToExclude`.
  */
  subDirsIn = entries:
    filter (name: entries.${name} == "directory" && !(elem name foldersToExclude)) (attrNames entries);

  # -- shared call primitive

  /**
  Import the module at `path` and call it with `args`, filtered to the
  module's own declared parameters when it uses a closed attrset pattern.
  (unchanged from original - see prior docstring)
  */
  importModuleFiltered = args: path: let
    required = functionArgs (import path);
  in
    if required == {}
    then import path args
    else import path (filterAttrs (name: _: elem name (attrNames required)) args);

  # -- importNixModules

  /**
  Import every `.nix` module found by `meta.listNixModules` under `path`.
  (unchanged from original)
  */
  importNixModules = path: map import (listNixModules path);

  # -- shared: one-level named directory walk with stem bookkeeping
  #> Internal helper feeding importAttrs. "readDir, filter, import, keep
  #> the real on-disk name + accumulated path" computed exactly once.

  walkDirNamed = {
    dir,
    stemSoFar ? [],
    exclude ? [],
  }: let
    entries = readDir dir;
    dirNames = filter (name: entries.${name} == "directory" && !(elem name exclude)) (
      attrNames entries
    );
  in
    map (name: {
      inherit name; #! exact on-disk name, never toCamelCase or similar
      raw = import (dir + "/${name}");
      stem = stemSoFar ++ [name];
    })
    dirNames;

  # -- importAttrs / importNames / importValues

  /**
    Import each immediate subdirectory of `dir` as a module, keyed by its
    exact on-disk name (never case-transformed). Returns `{ value; stems; }`:
    `value` is the merge-under-defaults result - if `dir/default.nix`
    exists, its declared attrset is recursively merged underneath every
    imported entry, the entry remaining the override for keys it declares
    while inheriting unspecified keys from the directory declaration, same
    as before this patch; `stems` mirrors `value`'s keys with each leaf
    replaced by the real accumulated on-disk path segments to that
    subdirectory.

    One-level only - does not recurse. Distinct from `importTree`'s
    leaf-per-default.nix / mirror-and-recurse semantics - use this when
    subdirectories share common defaults they can override.

    BREAKING relative to the pre-stems version of this file: return shape
    changed from bare attrset to { value; stems; } - existing callers must
    be updated to read `.value`.

    # Inputs
    `path` (bare path form)
    : directory whose immediate subdirectories are imported; `exclude`
      defaults to `[]`, `stemSoFar` defaults to `[]`

    `path`, `exclude`, `stemSoFar` (attrset form)
    : `path` as above; `exclude` is a list of subdirectory names to skip;
      `stemSoFar` accumulates real path segments across nested calls

    # Type
    > importAttrs :: path -> { value :: AttrSet, stems :: AttrSet }
    > importAttrs :: { path :: path, exclude :: [string]?, stemSoFar :: [string]? } -> { value :: AttrSet, stems :: AttrSet }

    # Examples
    - importAttrs ./hosts

  \```nix
    { value = { Victus = {...}; }; stems = { Victus = [ "Victus" ]; }; }
  \```
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

    stemSoFar =
      if isAttrsArg && args ? stemSoFar
      then args.stemSoFar
      else relativeStem projectPath dir;

    entries = readDir dir;

    domainDefault =
      optionalAttrs
      (entries ? "default.nix")
      (import (dir + "/default.nix"));

    # Child dirs, minus exclude (same idea as walkDirNamed)
    childNames = filter (
      name:
        entries.${name}
        == "directory"
        && !(elem name exclude)
        && !(elem name foldersToExclude)
    ) (attrNames entries);

    hasSubdirs = path: let
      entries = readDir path;
    in
      any (entry: entries.${entry} == "directory") (attrNames entries);

    loadChild = name: let
      childPath = dir + "/${name}";
    in
      if hasSubdirs childPath
      then
        importAttrs {
          path = childPath;
          inherit exclude;
          stemSoFar = stemSoFar ++ [name];
        }
      else {
        value = recursiveUpdate domainDefault (import childPath);
        stems = stemSoFar ++ [name];
      };

    walked =
      map (name: {
        inherit name;
        raw = loadChild name;
        stem = stemSoFar ++ [name];
      })
      childNames;
  in {
    value =
      if walked == []
      then domainDefault
      else
        listToAttrs (
          map
          (walk: {
            inherit (walk) name;
            value = walk.raw.value;
          })
          walked
        );

    stems = listToAttrs (
      map
      (walk: {
        inherit (walk) name;
        value = walk.raw.stems;
      })
      walked
    );
  };

  /**
  Names of all immediate subdirectories of `dir`.
  */
  importNames = dir: attrNames (importAttrs dir).value;

  /**
  Imported values of all immediate subdirectories of `dir`.
  */
  importValues = dir: attrValues (importAttrs dir).value;

  # -- importAll / importAllPaths

  /**
  Recursively traverse `dir`, collecting either imported values or paths
  for all `.nix` files (except `default.nix`) and subdirectories, along
  with the real accumulated on-disk path segments ("stem") to each.

  Subdirectories with a `default.nix` are treated as a unit; others are
  recursed into. Excluded folder names (`foldersToExclude`) are pruned
  entirely. Internal primitive shared by `importAll`/`importAllPaths`.

  Returns `{ value; stems; }`: both flat lists, same order and length -
  `stems` elements are `[string]` path-segment lists, one per `value`
  element, since a flat list has no natural key to mirror an attrset by.

  # Inputs
  `collect`
  : `path -> any`, what to produce per matched item - `import path` for
    `importAll`, `path` itself for `importAllPaths`

  `recurse`
  : the 2-arg (dir, stemSoFar) recursive helper for this collector -
    `importAllRecurse` for `importAll`, `importAllPathsRecurse` for
    `importAllPaths`

  `dir`
  : directory to traverse

  `stemSoFar`
  : accumulated real path segments from the original root down to `dir`

  # Type
  > traverseDir :: (path -> any) -> (path -> [string] -> {value :: [any], stems :: [[string]]}) -> path -> [string] -> { value :: [any], stems :: [[string]] }
  */
  traverseDir = collect: recurse: dir: stemSoFar: let
    entries = readDir dir;

    fileNamesList = nixFilesIn entries;
    fileResults = map (name: collect (dir + "/${name}")) fileNamesList;
    fileStems = map (name: stemSoFar ++ [name]) fileNamesList;

    dirNamesList = subDirsIn entries;

    #> Each dir contributes both a value-chunk and a stems-chunk together,
    #> from the same branch (leaf vs recurse), so they can never desync.
    dirWalks =
      map (
        name: let
          subPath = dir + "/${name}";
          subEntries = readDir subPath;
          hasDefault = subEntries ? "default.nix" && subEntries."default.nix" == "regular";
          childStem = stemSoFar ++ [name];
        in
          if hasDefault
          then {
            value = [(collect (subPath + "/default.nix"))];
            stems = [childStem];
          }
          else recurse subPath childStem #! recurse already returns { value; stems; } - same shape
      )
      dirNamesList;
  in {
    value = fileResults ++ flatten (map (w: w.value) dirWalks);
    stems = fileStems ++ flatten (map (w: w.stems) dirWalks);
  };

  /**
  Recursively import all `.nix` files (except `default.nix`) and
  subdirectories under `dir`. Returns `{ value; stems; }` - see
  `traverseDir` for the shape. Prefer `importAllNamed`/`importTree` when
  you need results keyed by name rather than a flat list.

  BREAKING: return shape changed from bare list to { value; stems; }.

  # Type
  > importAll :: path -> { value :: [any], stems :: [[string]] }
  */
  importAll = dir: traverseDir import importAllRecurse dir [];
  importAllRecurse = dir: stemSoFar: traverseDir import importAllRecurse dir stemSoFar;

  /**
  Paths (not imported values) of all `.nix` files (except `default.nix`)
  and default.nix-bearing subdirectories under `dir`. Returns
  `{ value; stems; }` - see `traverseDir` for the shape.

  Prefer this over `importAll` when used in NixOS `imports` - paths give
  better error traces and let `disabledModules` work correctly.

  BREAKING: return shape changed from bare list to { value; stems; }.

  # Type
  > importAllPaths :: path -> { value :: [path], stems :: [[string]] }
  */
  importAllPaths = dir: traverseDir (p: p) importAllPathsRecurse dir [];
  importAllPathsRecurse = dir: stemSoFar: traverseDir (p: p) importAllPathsRecurse dir stemSoFar;

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
    false, such subdirectories are skipped entirely.

  Throws if a file-derived key and a directory-derived key collide at the
  same level.

  Returns `{ value; stems; }`. `value` is unchanged from before this
  patch. `stems` mirrors `value`'s exact shape: a file entry's stem is
  the accumulated path to that file (including its `.nix` extension); a
  leaf directory's stem is the accumulated path to that directory; a
  recursed-into directory's stem is the nested stems attrset from that
  recursive call, mirroring how `value` nests one level down for the
  same case.

  BREAKING: return shape changed from bare attrset to { value; stems; }.

  `default.nix` is always excluded as a sibling file. `foldersToExclude`
  is always excluded, unconditionally. `exclude` is an additional list of
  exact names to skip at every level. `excludePrefixes` additionally
  skips any name starting with one of the given prefixes at every level,
  defaulting to `defaultExcludePrefixes`.

  This is the shared core behind `importAllNamed` (`recursive = true`)
  and `importAllMerged` (`recursive = false`).

  # Inputs
  `dir` : directory to traverse
  `args` : args attrset to (filtered-)call every discovered module with, default `{}`
  `exclude` : exact file/directory names to skip at every level, default `[]`
  `excludePrefixes` : name prefixes to skip at every level, default `defaultExcludePrefixes`
  `recursive` : whether to descend into subdirectories that lack a `default.nix`, default `true`

  # Type
  > importTree :: { dir :: path, args :: AttrSet?, exclude :: [string]?, excludePrefixes :: [string]?, recursive :: bool? } -> { value :: AttrSet, stems :: AttrSet }
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

    go = dir: stemSoFar: let
      entries = readDir dir;

      fileNames = filter (
        name:
          (entries.${name} == "regular")
          && (hasSuffix ".nix" name)
          && (name != "default.nix")
          && !(isExcluded name)
      ) (attrNames entries);

      #! key = filename with .nix stripped, matching fileResults exactly
      fileStems = listToAttrs (
        map (name: {
          name = substring 0 (stringLength name - 4) name;
          value = stemSoFar ++ [name]; #! full filename incl. .nix in the stem value itself
        })
        fileNames
      );

      fileResults = listToAttrs (
        map (name: {
          name = substring 0 (stringLength name - 4) name;
          value = importModuleFiltered args (dir + "/${name}");
        })
        fileNames
      );

      dirNames = filter (name: entries.${name} == "directory" && !(isExcluded name)) (attrNames entries);

      #> Each dir produces its value-contribution and stems-contribution
      #> together from the same branch, so they can never desync.
      dirWalks =
        map (
          name: let
            subPath = dir + "/${name}";
            subEntries = readDir subPath;
            hasDefault = subEntries ? "default.nix" && subEntries."default.nix" == "regular";
            childStem = stemSoFar ++ [name];
          in
            if hasDefault
            then {
              value = {${name} = importModuleFiltered args (subPath + "/default.nix");};
              stems = {${name} = childStem;};
            }
            else if recursive
            then let
              sub = go subPath childStem;
            in {
              value = {${name} = sub.value;};
              stems = {${name} = sub.stems;};
            }
            else {
              value = {};
              stems = {};
            }
        )
        dirNames;

      dirResults = map (w: w.value) dirWalks;
      dirStemsResults = map (w: w.stems) dirWalks;

      merged = foldl' (acc: sub: acc // sub) fileResults dirResults;
      mergedStems = foldl' (acc: sub: acc // sub) fileStems dirStemsResults;

      fileKeys = attrNames fileResults;
      dirKeys = flatten (map attrNames dirResults);
      collisions = filter (k: elem k fileKeys) dirKeys;
    in
      assert withContext {
        name = "importTree";
        context = "checking for file/directory key collisions in ${toString dir}";
        assertion = collisions == [];
        message = "key(s) [${concat ", " collisions}] produced by both a .nix file and a subdirectory in the same folder - rename one";
      }; {
        value = merged;
        stems = mergedStems;
      };
  in
    go dir [];

  /**
  Recursively import `dir`, keyed by name, nested to mirror the folder
  tree. `importTree` with `recursive = true`. Returns `{ value; stems; }`
  - see `importTree` for the shape and behavior.

  BREAKING: return shape changed from bare attrset to { value; stems; }.

  # Type
  > importAllNamed :: { dir :: path, args :: AttrSet?, exclude :: [string]?, excludePrefixes :: [string]? } -> { value :: AttrSet, stems :: AttrSet }
  */
  importAllNamed = args: importTree (args // {recursive = true;});

  /**
  Import only the immediate `.nix` files and default.nix-bearing
  subdirectories of `dir` - no recursion into plain subdirectories.
  `importTree` with `recursive = false`. Returns `{ value; stems; }` -
  see `importTree` for the shape and behavior.

  BREAKING: return shape changed from bare attrset to { value; stems; }.

  # Type
  > importAllMerged :: { dir :: path, args :: AttrSet?, exclude :: [string]?, excludePrefixes :: [string]? } -> { value :: AttrSet, stems :: AttrSet }
  */
  importAllMerged = args: importTree (args // {recursive = false;});

  # -- importRegistry

  /**
  Import a directory of stem-organized `.nix` data files into a single
  registry attrset, tagging each entry with the stem(s) it was found
  under. (unchanged behavior for `value` - see original docstring for
  the full stem-organized/categories-tagging behavior.)

  Returns `{ value; paths; }`. NOTE naming: this function already had
  TWO other things called "stem" before this patch - the `stems`
  parameter (domain path segments under `root` to descend through, e.g.
  `["data"]`, UNCHANGED meaning) and the local `stemOf`/`stem` (a
  filename with `.nix` stripped, used as both an entry's key and tagged
  into its `categories`, UNCHANGED). Neither of those is the real
  on-disk path manifest this patch adds - to avoid a third, colliding
  meaning of "stem" in one function, the new manifest is called `paths`
  here specifically, not `stems`. `paths` mirrors `value`'s keys; each
  leaf is the real accumulated on-disk path segments (this level's
  `stems`, plus the entry's actual filename).

  BREAKING: return shape changed from bare attrset to { value; paths; }.

  # Inputs
  `value` (path or string form)
  : used directly as `root`; all other options take their defaults

  `value` (attrset form)
  : `root` - directory or string root to resolve via `mkPath`
    `stems` - path segments under `root` to descend through, default `["data"]`
    `recursive` - whether to also descend into subdirectories beyond `stems`, default `true`
    `extraArgs`/`args` - args attrset passed to `importModuleFiltered` for each data file

  # Type
  > importRegistry :: path | string | { root :: path | string, stems :: [string]?, recursive :: bool?, extraArgs :: AttrSet? } -> { value :: AttrSet, paths :: AttrSet }
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
      context = concat " " [
        "resolving"
        "registry"
        "root"
      ];
      assertion = args ? root && (isPath args.root || isString args.root);
      message = "expected `root` to be a path or string";
    };
      args.root;

    stems = args.stems or ["data"]; #! UNCHANGED meaning: domain segments under root to descend through
    recursive = args.recursive or true;
    extraArgs = args.extraArgs or (args.args or {});

    path = mkPath {inherit root stems;};
    entries = readDir path;

    stemOf = name: substring 0 (stringLength name - 4) name; #! UNCHANGED: filename minus .nix

    fileNamesList = nixFilesIn entries;

    direct = listToAttrs (
      map (
        name: let
          stem = stemOf name;
        in {
          name = stem;
          value = let
            raw = importModuleFiltered extraArgs (path + "/${name}");
          in
            mapAttrs (
              _: entry:
                entry
                // {
                  categories = unique ((toList (entry.categories or [])) ++ [stem]);
                }
            )
            raw;
        }
      )
      fileNamesList
    );

    #> real on-disk path to each direct entry's source .nix file:
    #> this level's own accumulated `stems`, PLUS the actual filename.
    directPaths = listToAttrs (
      map (name: {
        name = stemOf name;
        value = stems ++ [name];
      })
      fileNamesList
    );
  in
    if recursive
    then let
      subWalks = map (
        name:
          importRegistry {
            inherit root recursive extraArgs;
            stems = stems ++ [name];
          }
      ) (subDirsIn entries);
    in {
      value = direct // foldl' (acc: w: acc // w.value) {} subWalks;
      paths = directPaths // foldl' (acc: w: acc // w.paths) {} subWalks;
    }
    else {
      value = direct;
      paths = directPaths;
    };
in
  exports // {__rootAliases = exports;}
