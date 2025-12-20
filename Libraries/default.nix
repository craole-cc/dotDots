#TODO: Allow disabling root aliases
{
  lib ? import <nixpkgs/lib>,
  pkgs ? import <nixpkgs> {},
  name ? "lix",
  src ? ./.,
  collisionStrategy ? "warn",
  # enableCaching ? true,
  runTests ? true,
  # debugMode ? false,
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
  inherit (builtins) readDir pathExists;
  inherit
    (lib.attrsets)
    attrNames
    foldlAttrs
    isAttrs
    mapAttrs
    removeAttrs
    filterAttrs
    ;
  inherit (lib.fixedPoints) makeExtensible;
  inherit
    (lib.strings)
    hasPrefix
    hasSuffix
    removeSuffix
    removePrefix
    ;
  inherit (lib.lists) elem filter foldl' findFirst;
  inherit (builtins) trace;
  inherit (lib.trivial) isFunction;

  # Helper function to get relative path
  getRelativePath = base: target:
    removePrefix (toString base + "/") (toString target);

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

          #> Filter private functions (except metadata and docs)
          allAttrs = attrNames importedModule;
          attrsToRemove =
            ["_rootAliases"]
            ++ (
              filter (
                name:
                  hasPrefix "_" name
                  && name != "_rootAliases"
                  && name != "_tests"
                  && name != "__meta"
                  && name != "__doc"
              )
              allAttrs
            )
            ++ (
              if !runTests
              then ["_tests"]
              else []
            );

          cleanModule = removeAttrs importedModule attrsToRemove;

          # Find documentation in multiple locations
          # 1. First check for co-located docs
          possibleDocFiles = [
            #~@ Same directory as module
            (dir + "/${moduleName}.md")
            (dir + "/README.md")
            (dir + "/readme.md")

            #~@ Docs subdirectory
            (dir + "/docs/${moduleName}.md")
            (dir + "/docs/README.md")

            #~@ Documentation tree mirror (relative to source dir)
            (src + "/Documentation/${getRelativePath src dir}/${moduleName}.md")
            (src + "/Documentation/${getRelativePath src dir}/README.md")
          ];

          docFile =
            findFirst (path: path != null && pathExists (toString path))
            null
            possibleDocFiles;

          # Determine documentation source
          docsInfo =
            if docFile != null
            then {
              type = "markdown";
              source = docFile;
              available = true;
              # List all existing doc files for this module
              locations = filter (path: pathExists (toString path)) possibleDocFiles;
            }
            else if cleanModule ? __doc
            then {
              type = "string";
              source = cleanModule.__doc;
              available = true;
              locations = [];
            }
            else {
              type = "none";
              source = null;
              available = false;
              locations = [];
            };

          # Add comprehensive metadata to the module
          moduleWithMeta =
            cleanModule
            // {
              __meta = {
                # Module identity
                name = moduleName;
                path = filePath;

                # Documentation info
                docs = docsInfo;

                # Module structure
                exports = attrNames cleanModule;
                functions = attrNames (filterAttrs (_: value: isFunction value) cleanModule);
                values = attrNames (filterAttrs (_: value: !isFunction value) cleanModule);

                # File info
                directory = toString dir;
                filename = entryName;

                # Build info
                timestamp = builtins.currentTime;
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
      inherit pkgs;
    };
in {${name} = finalLib;}
