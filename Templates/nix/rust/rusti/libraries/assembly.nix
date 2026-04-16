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
{lib}: let
  # ---------------------------------------------------------------------------
  # stdlib — only stock nixpkgs lib, nothing custom
  # ---------------------------------------------------------------------------
  inherit (lib.attrsets) attrNames attrValues filterAttrs mergeAttrsList;
  inherit (lib.filesystem) isPath pathIsRegularFile pathType readDir;
  inherit (lib.lists) concatMap elem filter flatten foldl' isList map optionals toList;
  inherit (lib.strings) hasSuffix removeSuffix;
  inherit (lib.trivial) functionArgs isFunction;

  # ---------------------------------------------------------------------------
  # assemble
  # ---------------------------------------------------------------------------

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
  ```nix
  assemble {
    start   = lib;
    entries = [ ./filesystem ./attrsets ];
    scope   = acc: acc;
  }

  assemble {
    start  = lib.filesystem;
    entries = [ ./paths.nix ./imports.nix ];
    scope  = acc: lib // { filesystem = acc; };
  }
  ```
  */
  assemble = {
    start,
    entries,
    scope ? (acc: acc),
    priority ? [],
    ignore ? [],
    dependencies ? [],
  }: let
    orderedEntries =
      if isList entries
      then let
        #? Explicit list — only strip ignored entries, keep caller's order.
        notIgnored =
          filter
          (entry: !(elem (baseNameOf (toString entry)) ignore))
          entries;
        prioritized =
          filter
          (entry: elem (baseNameOf (toString entry)) priority)
          notIgnored;
        remaining =
          filter
          (entry: !(elem (baseNameOf (toString entry)) priority))
          notIgnored;
      in
        prioritized ++ remaining
      else let
        #? Directory — sort by priority then alphabetically.
        dir = readDir entries;
        names =
          filter
          (name:
            !(elem name ignore)
            && name != "default.nix"
            && (dir.${name}
              == "directory"
              || (dir.${name} == "regular" && hasSuffix ".nix" name)))
          (attrNames dir);

        prioritized = filter (name: elem name names) priority;
        remaining = filter (name: !elem name prioritized) names;
      in
        map (name: entries + "/${name}") (prioritized ++ remaining);
  in
    foldl'
    (acc: entry: let
      baseLib = scope acc;

      # Inject dependency extensions so each entry sees them in its `lib`.
      libForEntry =
        foldl'
        (depLib: depPath:
          depLib // (import depPath {lib = depLib;}))
        baseLib
        dependencies;
    in
      acc // (import entry {lib = libForEntry;}))
    start
    orderedEntries;

  # ---------------------------------------------------------------------------
  # Path discovery
  # ---------------------------------------------------------------------------

  /**
  Directory basenames always skipped during discovery.
  */
  foldersToExclude = ["archives" "review" "temp" "tmp"];

  /**
  True for regular `.nix` files other than `default.nix`.
  */
  isNixFile = name: entry:
    entry == "regular" && hasSuffix ".nix" name && name != "default.nix";

  /**
  True for traversable subdirectories not in `foldersToExclude`.
  */
  isIncludedDir = name: entry:
    entry == "directory" && !(elem name foldersToExclude);

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

    filePaths =
      map
      (name: path + "/${name}")
      (filter
        (name: !(elem name ignore) && isNixFile name entries.${name})
        (attrNames entries));

    dirPaths = concatMap (name: let
      subPath = path + "/${name}";
      subEntries = readDir subPath;
      hasDefault =
        subEntries ? "default.nix"
        && subEntries."default.nix" == "regular";
    in
      if hasDefault
      then [subPath]
      else
        optionals recurse
        collectFromDir {
          path = subPath;
          inherit recurse ignore;
        }) (filter (
      name:
        !(elem name ignore)
        && isIncludedDir name entries.${name}
    ) (attrNames entries));
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
      map
      (
        p:
          if pathType p == "directory"
          then
            collectFromDir {
              path = p;
              inherit recurse ignore;
            }
          else
            optionals (
              pathIsRegularFile p
              && !(elem (baseNameOf p) ignore)
              && hasSuffix ".nix" (baseNameOf p)
            ) [p]
      ) (toList path)
    );

  # ---------------------------------------------------------------------------
  # Import helpers
  # ---------------------------------------------------------------------------

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
  inferNamespace = path:
    removeSuffix ".nix" (baseNameOf (toString path));

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

  /**
  Resolve importable paths from normalized filesystem input.

  # Type
  ```
  importPaths :: path | [path] | AttrSet -> [path]
  ```
  */
  importPaths = input:
    collectPaths {
      inherit (normalizeInput {} input) path recurse ignore;
    };

  /**
  Import multiple attrset fragments, merge them, and attach `__meta`.

  # Type
  ```
  importAttrs :: path | [path] | AttrSet -> AttrSet
  ```
  */
  importAttrs = input: let
    n = normalizeInput {} input;
    paths = collectPaths {inherit (n) path recurse ignore;};
    all = mergeAttrsList (map (p: importWithFilteredArgs p n.args) paths);
    names = attrNames all;
    values = attrValues all;
  in
    {__meta = {inherit names values all;};} // all;

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
    paths = collectPaths {inherit (n) path recurse ignore;};
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
      entries = paths;
      scope = acc: libToUse // {${namespace} = acc;}; # ← was `lib //`
      priority = n.priority or [];
      ignore = n.ignore   or [];
      dependencies = n.dependencies or [];
    };
    names = attrNames all;
    values = attrValues all;
  in {
    ${namespace} = all;
    __meta.${namespace} = {inherit namespace names values all paths;};
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
