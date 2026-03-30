{lib, ...}: let
  __exports =
    {
      inherit
        paths
        predicates
        reading
        sources
        ;
    }
    // paths
    // predicates
    // reading
    // sources
    // {};

  paths = {
    inherit
      (lib.filesystem)
      baseNameOf
      dirOf
      ;

    inherit
      (lib.path)
      append
      removePrefix
      splitRoot
      subpath
      ;

    inherit
      (builtins)
      path
      toPath
      ;

    pathHasPrefix = lib.path.hasPrefix;
    isStorePath = lib.path.hasStorePathPrefix;
  };

  predicates = {
    inherit
      (lib.filesystem)
      isPath
      pathIsDirectory
      pathIsRegularFile
      ;

    inherit
      (lib.path)
      isAbsolute
      hasStorePathPrefix
      ;

    inherit
      (builtins)
      pathExists
      ;

    hasPrefix = lib.path.hasPrefix;
  };

  reading = {
    inherit
      (lib.filesystem)
      hashFile
      listFilesRecursive
      locateDominatingFile
      packagesFromDirectoryRecursive
      pathType
      readDir
      readFileType
      resolveDefaultNix
      ;

    inherit
      (lib.strings)
      fileContents
      ;

    inherit
      (builtins)
      readFile
      ;
  };

  sources = {
    inherit
      (lib.filesystem)
      haskellPathsInDir
      ;

    inherit
      (lib.sources)
      canCleanSource
      cleanSource
      cleanSourceWith
      filterSource
      pathHasContext
      sourceByRegex
      sourceFilesBySuffix
      ;
  };
in
  __exports
