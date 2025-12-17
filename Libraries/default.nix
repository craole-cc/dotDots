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
    typeOf
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
    # Simple regex to extract documentation comments at the top of the file
    # This matches /** ... */ style comments
    docMatch = builtins.match ''/\*\*([^*]*\*+(?:[^/*][^*]*\*+)*)/'' content;
  in
    if docMatch != null
    then builtins.head docMatch
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
          rawModule = import (dir + "/${entryName}");
          importedModule =
            if isFunction rawModule
            then let
              result = rawModule env;
            in
              if result == null || !(isAttrs result)
              then throw "Module ${entryName} must return an attribute set, got ${typeOf result}"
              else result
            else if isAttrs rawModule
            then rawModule
            else throw "Module ${entryName} must be either a function or attribute set";

          # Extract root aliases if present
          # rootAliases = importedModule._rootAliases or {};

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
          moduleDoc = extractDoc (dir + "/${entryName}");
          moduleWithMeta =
            cleanModule
            // {
              __meta = {
                file = dir + "/${entryName}";
                name = moduleName;
                path = "${dir}/${entryName}";
                # Store the source location for documentation
                __toString = self: toString self.file;
              };
            }
            // optionalAttrs (moduleDoc != null) {__doc = moduleDoc;};
        in {
          modules = {${moduleName} = moduleWithMeta;};
          rootAliases = importedModule._rootAliases or {};
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

  # Function to expose modules with their metadata
  exposeModules = modules: let
    # Function to convert module path to attribute path
    pathToAttrs = path:
      foldl'
      (acc: part: acc // {${part} = acc.${part} or {};})
      {}
      (splitString "/" (removeSuffix ".nix" (toString path)));

    # Build a flat attribute set with all modules
    flatModules =
      mapAttrsRecursive
      (
        path: module:
          if module ? __meta
          then module
          else module
      )
      modules;
  in
    flatModules;

  finalLib =
    removeAttrs customLib ["__unfix__" "unfix" "extend"]
    // {
      inherit extend lib;
      std = lib;
      # Expose modules with their paths
      __modules = exposeModules customLib;
    };
in {
  ${name} = finalLib;
}
