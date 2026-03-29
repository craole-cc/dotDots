{lib, ...}: {
  inherit
    (lib.filesystem)
    baseNameOf
    dirOf
    hashFile
    haskellPathsInDir
    isPath
    listFilesRecursive
    locateDominatingFile
    packagesFromDirectoryRecursive
    pathIsDirectory
    pathIsRegularFile
    pathType
    readDir
    readFileType
    resolveDefaultNix
    ;
  inherit
    (builtins)
    #~@ Reading
    readFile
    #~@ Predicates
    pathExists
    #~@ Path manipulation
    toPath
    #~@ Source
    filterSource
    path
    ;
  inherit (lib.strings) fileContents;

  inherit
    (lib.path)
    #~@ Construction
    append
    splitRoot
    subpath
    #~@ Transformation
    removePrefix
    #~@ Predicates
    isAbsolute
    hasPrefix
    hasStorePathPrefix
    ;
  pathHasPrefix = lib.path.hasPrefix;
  isStorePath = lib.path.hasStorePathPrefix;

  inherit
    (lib.sources)
    #~@ Source filtering
    cleanSource
    cleanSourceWith
    sourceByRegex
    sourceFilesBySuffix
    pathHasContext
    canCleanSource
    ;
}
