{
  lib ? import <nixpkgs/lib>,
  name ? "lix",
  collisionStrategy ? "warn",
  runTests ? true,
  exportPrivate ? true,
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
  inherit (builtins) readDir;
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
    ;
  inherit (lib.lists) elem filter foldl';
  inherit (builtins) trace attrValues;
  inherit (lib.trivial) isFunction;

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
        metadata = {}; # Store metadata separately
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
          metadata = processed.metadata;
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

          # Store metadata
          moduleMetadata = {
            file = filePath;
            name = moduleName;
            path = "${toString dir}/${entryName}";
            hasDoc = cleanModule ? __doc;
          };

          # Create module with metadata
          moduleWithMeta =
            cleanModule
            // {
              __meta = moduleMetadata;
            };
        in {
          modules = {${moduleName} = moduleWithMeta;};
          rootAliases = rootAliases;
          metadata = {${moduleName} = moduleMetadata;};
        }
        else scanResults;

      processed = mapAttrs (name: type: processEntry name type) entries;

      # Merge all results from this directory
      merged =
        foldlAttrs (acc: _: value: {
          modules = acc.modules // value.modules;
          rootAliases = acc.rootAliases // value.rootAliases;
          metadata = acc.metadata // value.metadata;
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
    library
    // {
      # Add metadata accessor functions
      __libMeta = {
        modules = results.metadata;
        rootAliases = results.rootAliases;
      };

      # Helper to get module documentation
      getModuleDoc = path: let
        module = getAttrFromPath path self;
      in
        if module ? __doc
        then module.__doc
        else null;

      # Helper to get module metadata
      getModuleMeta = path: let
        module = getAttrFromPath path self;
      in
        if module ? __meta
        then module.__meta
        else null;

      # Helper to get all modules with their metadata
      listModules = let
        flattenMetadata = metadata: let
          go = path: value:
            if value ? file # This is a leaf module
            then [
              {
                path = path;
                meta = value;
              }
            ]
            else
              # This is a directory, recurse
              attrValues (mapAttrs (name: val: go (path ++ [name]) val) value);
        in
          go [] metadata;
      in
        flattenMetadata results.metadata;
    });

  extend = f: customLib.extend f;

  # Add top-level documentation helpers
  finalLib =
    removeAttrs customLib ["__unfix__" "unfix" "extend"]
    // {
      inherit extend lib;
      std = lib;

      # Documentation system
      doc = {
        # Get documentation for any path in the library
        get = path: let
          value = getAttrFromPath path customLib;
        in
          if isFunction value
          then {
            type = "function";
            value = value;
            # Nix will attach function docs automatically
          }
          else if isAttrs value && value ? __doc
          then {
            type = "module";
            value = value;
            doc = value.__doc;
            meta = value.__meta or null;
          }
          else if isAttrs value
          then {
            type = "module";
            value = value;
            meta = value.__meta or null;
          }
          else {
            type = "value";
            value = value;
          };

        # List all modules with their paths
        list = customLib.listModules;

        # Get metadata for a module
        meta = path: customLib.getModuleMeta path;

        # Get documentation for a module
        module = path: customLib.getModuleDoc path;
      };
    };
in {
  ${name} = finalLib;
}
