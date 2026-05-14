/**
libraries/assembly.nix

Self-contained assembly and filesystem-import helpers.

Provides `assemble`, path-discovery utilities, and `importLibs` using only
stock nixpkgs lib — no custom extensions, no circular dependencies.

Intended as a zero-dependency bootstrap that other library namespaces
(filesystem, attrsets, strings, …) can import without causing recursion.

# Exports
- `assemble`          – sequential module assembler
- `collectFromDir`    – single-directory path collector
- `collectPaths`      – multi-path / file / list collector
- `normalizeInput`    – input normalizer for import helpers
- `inferNamespace`    – namespace name inferred from a path
- `importWithFilteredArgs` – tolerant single-file importer
- `importPaths`       – alias: collect importable paths
- `importAttrs`       – merge imported attrset fragments
- `importLibs`        – assemble a staged library namespace
*/
{
  lib,
  paths,
  ...
}: let
  # stdlib — only stock nixpkgs lib, nothing custom
  inherit (lib.attrsets) attrNames attrValues filterAttrs;
  inherit
    (lib.filesystem)
    isPath
    pathIsRegularFile
    pathType
    readDir
    ;
  inherit
    (lib.lists)
    concatMap
    elem
    filter
    flatten
    foldl'
    isList
    map
    optionals
    toList
    ;
  inherit (lib.strings) hasSuffix match removeSuffix;
  inherit (lib.trivial) functionArgs isFunction;

  # assemble

  /**
  Assemble a list of modules in sequence, passing each module the
  progressively extended accumulator.

  Avoids fixed-point recursion (`lib.extend`) while still allowing later
  namespaces to depend on earlier custom namespaces assembled in the same run.

  # Type
  ```
  assemble :: {
    start      :: AttrSet;
    entries    :: path | [path];   -- directory or explicit list
    scope      :: AttrSet -> AttrSet;
    priority   :: [string];        -- basenames imported first
    ignore     :: [string];        -- basenames skipped entirely
    dependencies :: [path];        -- extra lib extensions injected per entry
  } -> AttrSet
  ```

  # Examples

  ## 1 – Simplest use: scan a directory, fold into `lib`

  Given a directory `./extensions/` containing:
    - `strings.nix`   → `{ lib }: { capitalize = s: ...; trimLines = s: ...; }`
    - `attrs.nix`     → `{ lib }: { mapKeys = f: set: ...; }`
    - `paths.nix`     → `{ lib }: { toRelative = base: p: ...; }`

  Each file receives the *already-extended* `lib`, so `attrs.nix` can call
  functions defined in `strings.nix`, and `paths.nix` can call functions from
  both earlier files — with no fixed-point needed.

  ```nix
  myLib = assemble {
    start   = lib;
    entries = ./extensions;    # scans dir; alphabetical, skips default.nix
    scope   = acc: acc;        # each entry receives the full growing acc
  };

  # Result (conceptually):
  # myLib == lib // { capitalize = …; trimLines = …; }    ← from strings.nix
  #              // { mapKeys = …; }                       ← from attrs.nix
  #              // { toRelative = …; }                    ← from paths.nix
  ```

  ---

  ## 2 – Priority + ignore: control load order explicitly

  `meta.nix` defines `mkVersion` and `mkLabel` — foundational helpers that
  later files depend on.  `legacy.nix` is obsolete and must be skipped.

  ```nix
  myLib = assemble {
    start    = lib;
    entries  = ./lib;
    priority = [ "meta.nix" "types.nix" ];   # loaded before anything else
    ignore   = [ "legacy.nix" "wip.nix"  ];  # skipped entirely
    scope    = acc: acc;
  };
  # Load order: meta.nix → types.nix → (everything else, alpha-sorted)
  ```

  ---

  ## 3 – Nested namespace with `scope`: build a sub-library

  When entries should extend a *sub-key* (e.g. `lib.custom`) rather than the
  top-level `lib`, `scope` re-wraps the accumulator before each import so the
  entry's `lib` argument looks like standard nixpkgs `lib` with the growing
  custom namespace merged in.

  ```nix
  # Each file under ./custom/ receives:
  #   lib == <nixpkgs lib> // { custom = <everything assembled so far> }
  # so later files can call lib.custom.mkLabel, lib.custom.formatVersion, etc.

  customLib = assemble {
    start   = {};                              # accumulator starts empty
    entries = ./custom;                        # custom/mkLabel.nix, etc.
    scope   = acc: lib // { custom = acc; };   # re-expose acc as lib.custom
  };

  # Attach the finished sub-library to nixpkgs lib:
  finalLib = lib // { custom = customLib; };
  ```

  ---

  ## 4 – `dependencies`: inject per-entry lib extensions

  Some entries need a helper that is not yet part of the main accumulator
  (e.g. a shared utility defined in a sibling file).  `dependencies` injects
  those extensions into the `lib` seen by *every* entry without polluting the
  accumulated result.

  ```nix
  # ./helpers/debug.nix  →  { lib }: { trace = v: lib.traceValSeq v; }

  myLib = assemble {
    start        = lib;
    entries      = [ ./network.nix ./storage.nix ./compute.nix ];
    scope        = acc: acc;
    dependencies = [ ./helpers/debug.nix ];   # every entry can call lib.trace
  };

  # lib.trace is available inside network.nix, storage.nix, compute.nix
  # but is NOT merged into myLib's final output.
  ```

  ---

  ## 5 – Full real-world composition

  Assembles a layered `myLib` from a `./lib/` directory.  Foundational modules
  load first, the `scope` re-wraps so each entry sees `lib.my.*` as it grows,
  and a shared `typecheck.nix` helper is injected without leaking.

  ```nix
  # ./lib/ contains:
  #   core.nix       – mkId, mkSlug   (no dependencies on other custom fns)
  #   meta.nix       – mkVersion      (depends on lib.my.mkSlug)
  #   system.nix     – mkHost         (depends on lib.my.mkVersion)
  #   home.nix       – mkUser         (depends on lib.my.mkHost)
  #   experimental.nix               (not ready; ignored)

  myLib = assemble {
    start        = {};
    entries      = ./lib;
    priority     = [ "core.nix" "meta.nix" ];
    ignore       = [ "experimental.nix" ];
    scope        = acc: lib // { my = acc; };
    dependencies = [ ./lib/internal/typecheck.nix ];
  };

  # Inside meta.nix (example entry):
  #   { lib }: {
  #     mkVersion = major: minor: patch:
  #       "${lib.my.mkSlug major}.${toString minor}.${toString patch}";
  #   }
  #
  # `lib.my.mkSlug` exists because core.nix was prioritized and already
  # folded into `acc` before meta.nix was imported.

  # Expose as a top-level overlay:
  finalLib = lib // { my = myLib; };
  ```
  */
  assemble = {
    start,
    entries,
    scope ? (acc: acc),
    priority ? [],
    ignore ? [],
    dependencies ? [],
    extraArgs ? {},
  }: let
    #> Automatically loaded first (in this order) when present and explicitly defined.
    autoPrioritize = names:
      filter (name: elem name names && !(elem name priority)) [
        "imports"
        "import"
        "import.nix"
        "base"
        "base.nix"
        "core"
        "core.nix"
      ];

    #> Automatically deferred to the end (in this order) when present and explicitly defined.
    autoDefer = names:
      filter (name: elem name names && !(elem name priority)) [
        "config"
        "config.nix"
        "exports"
        "export"
        "export.nix"
      ];

    orderedEntries =
      if isList entries
      then let
        #> Drop ignored entries and copy-files (unless explicitly prioritized).
        notIgnored =
          filter (
            entry: let
              name = baseNameOf (toString entry);
            in
              !(elem name ignore) && (!isNixFileCopy name || elem name priority)
          )
          entries;

        allNames = map (entry: baseNameOf (toString entry)) notIgnored;
        effectivePriority = (autoPrioritize allNames) ++ priority;
        deferred = autoDefer allNames;

        #> Walk effectivePriority in declared order
        prioritized = concatMap (name: filter (entry: baseNameOf (toString entry) == name) notIgnored) (
          filter (name: elem name allNames) effectivePriority
        );

        prioritizedNames = map (entry: baseNameOf (toString entry)) prioritized;

        #? Everything neither prioritized nor deferred, in original list order.
        middle =
          filter (
            entry: let
              name = baseNameOf (toString entry);
            in
              !(elem name prioritizedNames) && !(elem name deferred)
          )
          notIgnored;

        #? Deferred entries in autoLast order.
        deferredEntries = concatMap (name: filter (entry: baseNameOf (toString entry) == name) notIgnored) (
          filter (name: elem name allNames) deferred
        );
      in
        prioritized ++ middle ++ deferredEntries
      else let
        dir = readDir entries;
        names = filter (
          name:
            !(elem name ignore)
            && name != "default.nix"
            && (!isNixFileCopy name || elem name priority)
            && (dir.${name} == "directory" || (dir.${name} == "regular" && hasSuffix ".nix" name))
        ) (attrNames dir);

        effectivePriority = (autoPrioritize names) ++ priority;
        deferred = autoDefer names;

        #> Walk effectivePriority in declared order (only names that exist).
        prioritized = filter (name: elem name names) effectivePriority;

        #? Middle: alphabetical, excluding prioritized and deferred.
        middle = filter (name: !(elem name prioritized) && !(elem name deferred)) names;

        #? Deferred in autoLast order (only names that exist).
        deferredFiltered = filter (name: elem name names) deferred;
      in
        map (name: entries + "/${name}") (prioritized ++ middle ++ deferredFiltered);
  in
    foldl' (
      acc: entry: let
        baseLib = scope acc;
        libForEntry = foldl' (depLib: depPath: depLib // (import depPath {lib = depLib;})) baseLib dependencies;
      in
        acc // (importWithFilteredArgs entry ({lib = libForEntry;} // extraArgs))
    )
    start
    orderedEntries;

  # Path discovery

  /**
  Directory basenames always skipped during discovery.
  */
  foldersToExclude = [
    "archive"
    "archives"
    "review"
    "temp"
    "tmp"
  ];

  /**
  True for regular `.nix` files other than `default.nix`.
  */
  isNixFile = name: entry: entry == "regular" && hasSuffix ".nix" name && name != "default.nix";

  #> Matches macOS "name copy.nix" / "name copy 2.nix" backup naming.
  isNixFileCopy = name: match ".* copy( [0-9]+)?\\.nix" name != null;

  /**
  True for traversable subdirectories not in `foldersToExclude`.
  */
  isIncludedDir = name: entry: entry == "directory" && !(elem name foldersToExclude);

  /**
  Collect importable Nix paths from a single directory.

  Subdirectories that contain a `default.nix` are returned as directory paths
  (imported as a unit). Subdirectories without `default.nix` are traversed
  when `recurse = true`, otherwise skipped.

  # Type
  ```
  collectFromDir :: {
    path    :: path;
    recurse :: bool;
    ignore  :: [string];
  } -> [path]
  ```
  */
  collectFromDir = {
    path,
    recurse ? false,
    ignore ? [],
  }: let
    entries = readDir path;

    filePaths = map (name: path + "/${name}") (
      filter (name: !(elem name ignore) && isNixFile name entries.${name}) (attrNames entries)
    );

    dirPaths = concatMap (
      name: let
        subPath = path + "/${name}";
        subEntries = readDir subPath;
        hasDefault = subEntries ? "default.nix" && subEntries."default.nix" == "regular";
      in
        if hasDefault
        then [subPath]
        else
          optionals recurse (collectFromDir {
            path = subPath;
            inherit recurse ignore;
          })
    ) (filter (name: !(elem name ignore) && isIncludedDir name entries.${name}) (attrNames entries));
  in
    filePaths ++ dirPaths;

  /**
  Collect importable Nix paths from a path, list of paths, or single file.

  Delegates directories to `collectFromDir`; regular `.nix` files are
  returned as-is; anything else is silently skipped.

  # Type
  ```
  collectPaths :: {
    path    :: path | [path];
    recurse :: bool;
    ignore  :: [string];
  } -> [path]
  ```
  */
  collectPaths = {
    path,
    recurse ? false,
    ignore ? [],
  }:
    flatten (
      map (
        p:
          if pathType p == "directory"
          then
            collectFromDir {
              path = p;
              inherit recurse ignore;
            }
          else optionals (pathIsRegularFile p && !(elem (baseNameOf p) ignore) && hasSuffix ".nix" (baseNameOf p)) [p]
      ) (toList path)
    );

  # Import helpers

  /**
  Normalize a path, list-of-paths, or options attrset into a canonical form.

  # Type
  ```
  normalizeInput :: AttrSet -> (path | [path] | AttrSet) -> AttrSet
  ```
  */
  normalizeInput = defaults: input: let
    base =
      {
        recurse = false;
        namespace = null;
        args = {};
        priority = [];
        ignore = [];
        lib = null;
        start = null;
        scope = null;
      }
      // defaults;
  in
    if isPath input || isList input
    then base // {path = toList input;}
    else base // input;

  /**
  Infer a namespace name from a file or directory path.

  Files lose their trailing `.nix`; directories keep their basename.

  # Type
  ```
  inferNamespace :: path -> string
  ```
  */
  inferNamespace = path: removeSuffix ".nix" (baseNameOf (toString path));

  /**
  Import a path and pass only the arguments it actually declares.

  Keeps library imports tolerant of wider argument sets without explicit
  `...` in every file.

  # Type
  ```
  importWithFilteredArgs :: path -> AttrSet -> any
  ```
  */
  importWithFilteredArgs = path: args: let
    target = import path;
  in
    if isFunction target
    then let
      declared = attrNames (functionArgs target);
      filtered = filterAttrs (name: _: elem name declared) args;
    in
      target filtered
    else target;
  # importWithFilteredArgs = path: args: let
  #   target = import path;
  # in
  #   if isFunction target
  #   then let
  #     declared = attrNames (functionArgs target);
  #     filtered = filterAttrs (name: _: elem name declared) args;
  #   in
  #     target filtered
  #   else target;

  /**
  Resolve importable paths from normalized filesystem input.

  # Type
  ```
  importPaths :: path | [path] | AttrSet -> [path]
  ```
  */
  importPaths = input: collectPaths {inherit (normalizeInput {} input) path recurse ignore;};

  /**
  Import multiple attrset fragments, merge them, and attach `__meta`.

  # Type
  ```
  importAttrs :: path | [path] | AttrSet -> AttrSet
  ```
  */
  importAttrs = input: let
    n = normalizeInput {} input;
    libToUse =
      if n.lib != null
      then n.lib
      else lib;

    all = assemble {
      start = {};
      entries = collectPaths {inherit (n) path recurse ignore;};
      scope = acc: libToUse // acc;
      priority = n.priority or [];
      ignore = n.ignore or [];
      extraArgs =
        {
          inherit paths;
        }
        // n.args or {};
    };

    names = attrNames all;
    values = attrValues all;
  in
    {__meta = {inherit names values all;};} // all;
  # importAttrs = input: let
  #   n = normalizeInput {} input;
  #   libToUse =
  #     if n.lib != null
  #     then n.lib
  #     else lib;
  #   paths = collectPaths {inherit (n) path recurse ignore;};
  #   all = mergeAttrsList (map
  #     (p: importWithFilteredArgs p ({lib = libToUse;} // n.args))
  #     paths);
  #   names = attrNames all;
  #   values = attrValues all;
  # in
  #   {__meta = {inherit names values all;};} // all;

  /**
  Import library leaf files and mount them under a single namespace.

  Entries are assembled sequentially so later members can depend on earlier
  members via the namespace that is being built.

  # Type
  ```
  importLibs :: path | [path] | AttrSet -> AttrSet
  ```

  # Examples
  ```nix
  importLibs ./libraries/strings
  # => {
  #   strings = { optionalString = ...; ensurePrefix = ...; ... };
  #   __meta.strings = { namespace = "strings"; names = [...]; ... };
  # }

  importLibs {
    path      = ./libraries/strings;
    namespace = "myStrings";
    priority  = ["core.nix"];
    ignore    = ["experimental.nix"];
  }
  ```
  */
  importLibs = input: let
    n = normalizeInput {args = {};} input;
    libToUse =
      if n.lib != null
      then n.lib
      else lib;
    namespace =
      if n.namespace != null
      then n.namespace
      else inferNamespace n.path;

    #> Default start to the nixpkgs base for this namespace, if it exists

    all = assemble {
      start =
        if n.start != null
        then n.start
        else libToUse.${namespace} or {};
      entries = collectPaths {inherit (n) path recurse ignore;};
      scope =
        if n.scope != null
        then n.scope
        else acc: libToUse // {${namespace} = acc;};
      priority = n.priority or [];
      ignore = n.ignore or [];
      dependencies = n.dependencies or [];
      extraArgs =
        {
          inherit paths;
        }
        // n.args or {};
    };
    names = attrNames all;
    values = attrValues all;
  in {
    ${namespace} = all;
    __meta.${namespace} = {
      inherit
        namespace
        names
        values
        all
        ;
      paths = all.entries;
    };
  };
in {
  /**
  `lib.assembly` — all helpers live here so the file can be merged
  directly into lib:

  ```nix
  lib // (import ./assembly.nix { inherit lib; })
  # => lib // { assembly = { assemble, importLibs, … }; }
  ```

  Each namespace default.nix then does:

  ```nix
  { lib }: lib.assembly.importLibs ./.
  ```
  */
  assembly = {
    inherit
      assemble
      foldersToExclude
      isNixFile
      isIncludedDir
      collectFromDir
      collectPaths
      normalizeInput
      inferNamespace
      importWithFilteredArgs
      importPaths
      importAttrs
      importLibs
      ;

    # Alias kept for back-compat with existing callers.
    imports = importPaths;
  };
}
