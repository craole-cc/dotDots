{
  lib ? import <nixpkgs/lib>,
  name ? "lix",
  #| Collision Strategy
  #? Options: "warn", "error", "prefer-custom", "prefer-nixpkgs"
  collisionStrategy ? "warn",
  #| Performance Options
  #? Load modules only when accessed (experimental)
  enableLazyLoading ? false,
  #? Cache module imports to avoid re-evaluation
  enableCaching ? true,
  #| Safety & Validation
  #? Detect circular dependencies
  enableCycleDetection ? true,
  #? Validate module exports
  enableTypeChecking ? true,
  #| Testing & Debugging
  #? Automatically run module tests on load
  runTests ? true,
  #? Enable verbose logging
  debugMode ? true,
  #| Export Options
  #? Export functions starting with underscore
  exportPrivate ? false,
  #| Directory Exclusions
  excludedDirs ? [
    "review"
    "archive"
    "test"
    "tests"
    "tmp"
    "temp"
    "wip"
    "deprecated"
    "experimental"
    "backup"
  ],
  #| File Exclusions
  excludedFiles ? [
    "default.nix"
    # "_.nix"
    "flake.nix"
  ],
  #| File Pattern Exclusions
  excludedPatterns ? [
    " copy.nix"
    ".test.nix"
    ".spec.nix"
    ".bak.nix"
    ".old.nix"
  ],
}: let
  inherit (builtins) readDir;
  inherit
    (lib.attrsets)
    attrNames
    foldlAttrs
    isAttrs
    mapAttrs
    mapAttrsRecursive
    optionalAttrs
    removeAttrs
    ;
  inherit (lib.fixedPoints) makeExtensible;
  inherit
    (lib.strings)
    hasPrefix
    hasSuffix
    removeSuffix
    splitString
    ;
  inherit (lib.lists) elem filter foldl';
  inherit (builtins) trace;
  inherit (lib.trivial) isFunction;

  # Debug logging utility
  debug = msg: value:
    if debugMode
    then trace "[LibLoader] ${msg}" value
    else value;

  # Import cache for memoization
  importCache = {};

  # Helper to extract documentation from a file
  extractDoc = path: let
    content = builtins.readFile path;
    # Simple approach: extract first documentation block
    # Match /** ... */ (single-line for now)
    lines = builtins.split "\n" content;
    inDoc = false;
    docLines = [];

    # Simple state machine to extract doc
    processLine = line: state: let
      trimmed = builtins.replaceStrings [" " "\t"] ["" ""] line;
    in
      if !state.inDoc && builtins.substring 0 3 trimmed == "/**"
      then {
        inDoc = true;
        lines = state.lines ++ [builtins.substring 3 (builtins.stringLength line - 3) line];
      }
      else if state.inDoc && builtins.substring 0 2 trimmed == "*/"
      then {
        inDoc = false;
        lines = state.lines;
      }
      else if state.inDoc
      then {
        inherit (state) inDoc;
        lines = state.lines ++ [line];
      }
      else state;

    result =
      builtins.foldl' (state: line: processLine line state) {
        inDoc = false;
        lines = [];
      }
      lines;
  in
    if result.lines != []
    then builtins.concatStringsSep "\n" result.lines
    else null;

  #| Extensible Library Initializaton
  customLib = makeExtensible (self: let
    #~@ Handle collisions based on strategy
    handleCollisions = customAttrs: let
      nixpkgsAttrs = attrNames lib;
      customAttrNames = attrNames customAttrs;

      collisions = filter (name: elem name nixpkgsAttrs) customAttrNames;
      hasCollisions = collisions != [];

      baseMessage = "Custom library has collisions with nixpkgs lib: ${toString collisions}";
    in
      if !hasCollisions
      then lib // customAttrs
      else if collisionStrategy == "error"
      then throw baseMessage
      else if collisionStrategy == "warn"
      then trace "WARNING: ${baseMessage}" (lib // customAttrs)
      else if collisionStrategy == "prefer-custom"
      then lib // customAttrs
      else if collisionStrategy == "prefer-nixpkgs"
      then customAttrs // lib
      else lib // customAttrs; # Default to warn behavior

    #~@ Create a safe merged library
    safeLib = handleCollisions self;

    #| The complete environment for all modules
    env = {
      #> Individual libraries
      lib = lib; #? nixpkgs library
      _ = self; #? custom library
      safe = safeLib; #? merged library

      #> Short aliases
      l = lib;
      x = self;
      s = safeLib;

      #> Structured access
      libs = {
        nixpkgs = lib;
        custom = self;
        safe = safeLib;
      };
    };

    # Helper to scan a directory and return its contents as an attrset
    scanDir = dir: let
      entries = readDir dir;

      # Results accumulator
      scanResults = {
        modules = {}; # Module tree structure
        rootAliases = {}; # Functions to expose at root level
      };

      #~@ Check if a directory should be excluded
      isExcludedDir = dirName:
        elem dirName excludedDirs
        || (hasPrefix "." dirName); # Always exclude hidden directories

      #~@ Check if a file should be excluded
      isExcludedFile = fileName:
        elem fileName excludedFiles
        || foldl' (acc: pattern: acc || hasSuffix pattern fileName) false excludedPatterns;

      processEntry = entryName: entryType:
      #~@ Skip excluded directories
        if entryType == "directory" && isExcludedDir entryName
        then scanResults
        #~@ Process directories
        else if entryType == "directory"
        then let
          subdir = dir + "/${entryName}";
          processed = scanDir subdir;
        in {
          modules =
            if processed.modules != {}
            then {${entryName} = processed.modules;}
            else {};
          rootAliases = processed.rootAliases;
        }
        #> Process .nix files
        else if entryType == "regular" && hasSuffix ".nix" entryName && !isExcludedFile entryName
        then let
          moduleName = removeSuffix ".nix" entryName;
          filePath = dir + "/${entryName}";

          # Cache the import if caching is enabled
          rawModule =
            if enableCaching && importCache ? ${toString filePath}
            then importCache.${toString filePath}
            else let
              imported = import filePath;
            in
              if enableCaching
              then importCache // {${toString filePath} = imported;}
              else imported;

          importedModule =
            if isFunction rawModule
            then let
              result = rawModule env;
            in
              if result == null || !(isAttrs result)
              then throw "Module ${entryName} must return an attribute set, got ${builtins.typeOf result}"
              else result
            else if isAttrs rawModule
            then rawModule
            else throw "Module ${entryName} must be either a function or attribute set";

          # Extract root aliases if present
          rootAliases = importedModule._rootAliases or {};

          #> Filter private functions based on config
          allAttrs = attrNames importedModule;
          attrsToRemove =
            ["_rootAliases"]
            ++ (
              if exportPrivate
              then []
              else
                filter (
                  name:
                    hasPrefix "_" name
                    && name != "_rootAliases"
                    && name != "_tests" # Exclude _tests from this filter
                    && name != "__meta" # Don't remove __meta
                    && name != "__doc" # Don't remove __doc
                )
                allAttrs
            )
            ++ (
              if !runTests
              then ["_tests"] # Only remove _tests if runTests is false
              else []
            );

          cleanModule = removeAttrs importedModule attrsToRemove;

          # Add metadata to the module
          moduleWithMeta =
            cleanModule
            // {
              __meta = {
                file = filePath;
                name = moduleName;
                path = "${toString dir}/${entryName}";
                __toString = self: toString self.file;
              };
            };
        in {
          modules = {${moduleName} = moduleWithMeta;};
          rootAliases = rootAliases;
        }
        else scanResults;

      processed = mapAttrs (name: type: processEntry name type) entries;

      # Merge all results from this directory
      merged =
        foldlAttrs (acc: _: value: {
          modules = acc.modules // value.modules;
          rootAliases = acc.rootAliases // value.rootAliases;
        })
        scanResults
        processed;
    in
      merged;

    # Get the full scan results
    results = scanDir ./.;

    # Check for collisions between root aliases and top-level module names
    rootAliasNames = attrNames results.rootAliases;
    moduleTopLevelNames = attrNames results.modules;
    collisions = filter (name: elem name moduleTopLevelNames) rootAliasNames;

    # Handle root alias collisions based on strategy
    library =
      if collisions != []
      then
        if collisionStrategy == "error"
        then throw "Root aliases collide with modules: ${toString collisions}"
        else if collisionStrategy == "warn"
        then trace "WARNING: Root aliases override modules for: ${toString collisions}" (results.modules // results.rootAliases)
        else results.modules // results.rootAliases # Default/prefer-custom
      else results.modules // results.rootAliases;
  in
    library);

  /**
    Extend the library with new functions or overrides.

    # Type
    ```nix
    extend :: (Self -> Super -> AttrSet) -> AttrSet

  Arguments
  f: A function that takes two arguments:

  self: The new library instance (for forward references)

  super: The current library instance

  Returns: An attribute set of new or overridden functions.

  Returns
  A new library instance with the extensions applied.

  Examples
  let
    extended = _lib.extend (self: super: {
      # Add a new function
      newFunction = "I'm new!";

      # Override an existing function
      makeFirefoxExtensionUrl = id: "https://custom.example.com/${id}";

      # Add a new module
      utils = super.utils or {} // {
        helper = x: x * 2;
      };
    });
  in
    {
      original = _lib.makeFirefoxExtensionUrl "test";
      extended = extended.makeFirefoxExtensionUrl "test";
      new = extended.newFunction;
    }
  */
  extend = f: customLib.extend f;

  finalLib =
    removeAttrs customLib ["__unfix__" "unfix" "extend"]
    // {
      inherit extend lib;
      std = lib;
    };
in {
  ${name} = finalLib;
}
