{
  lib ? import <nixpkgs/lib>,
  name ? "lix",
  collisionStrategy ? "warn",
  enableCaching ? true,
  runTests ? true,
  debugMode ? false,
  exportPrivate ? false,
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
  excludedFiles ? [
    "default.nix"
    "flake.nix"
  ],
  excludedPatterns ? [
    " copy.nix"
    ".test.nix"
    ".spec.nix"
    ".bak.nix"
    ".old.nix"
  ],
}: let
  inherit (builtins) readDir match head;
  inherit
    (lib.attrsets)
    attrNames
    foldlAttrs
    isAttrs
    mapAttrs
    removeAttrs
    getAttrFromPath
    ;
  inherit (lib.fixedPoints) makeExtensible;
  inherit
    (lib.strings)
    hasPrefix
    hasSuffix
    removeSuffix
    concatStringsSep
    stringLength
    ;
  inherit (lib.lists) elem filter foldl' length elemAt;
  inherit (builtins) trace attrValues;
  inherit (lib.trivial) isFunction;

  # Create a documented function that also has the module attributes
  makeDocumentedModule = filePath: moduleAttrset: let
    # Try to extract documentation from the file
    extractDoc = path: let
      content = builtins.readFile path;
      # Look for /** at the beginning of the file
      lines = lib.splitString "\n" content;
      # Find the first non-empty line that starts with /**
      findDocStart = index:
        if index >= length lines
        then null
        else let
          line = elemAt lines index;
          trimmed = lib.removeSuffix " " (lib.removeSuffix "\t" line);
        in
          if lib.hasPrefix "/**" trimmed
          then index
          else findDocStart (index + 1);

      startIndex = findDocStart 0;
    in
      if startIndex == null
      then null
      else let
        # Collect lines until we find */
        collectDoc = index: acc:
          if index >= length lines
          then acc
          else let
            line = elemAt lines index;
            trimmed = lib.removeSuffix " " (lib.removeSuffix "\t" line);
          in
            if lib.hasPrefix "*/" trimmed
            then acc
            else collectDoc (index + 1) (acc ++ [line]);

        docLines = collectDoc (startIndex + 1) [];
      in
        concatStringsSep "\n" docLines;

    moduleDoc = extractDoc filePath;

    # Create the base function
    baseFunc = {...}: moduleAttrset;

    # Create documented function if we have docs
    documentedFunc =
      if moduleDoc != null
      then
        /**
        ${moduleDoc}
        */
        baseFunc
      else baseFunc;

    # Add module attributes to the function
    finalFunc = documentedFunc // moduleAttrset;
  in
    finalFunc;

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
        || (hasPrefix "." dirName);

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

          # Import the module
          rawModule = import filePath;

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
                    && name != "_tests"
                )
                allAttrs
            )
            ++ (
              if !runTests
              then ["_tests"]
              else []
            );

          cleanModule = removeAttrs importedModule attrsToRemove;

          # Create a documented module
          documentedModule = makeDocumentedModule filePath cleanModule;
        in {
          modules = {${moduleName} = documentedModule;};
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
        else results.modules // results.rootAliases
      else results.modules // results.rootAliases;
  in
    library);

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
