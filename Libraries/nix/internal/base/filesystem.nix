{
  lib,
  flatten ? false,
  ...
}: let
  __exports = {
    namespaced = {
      inherit
        access
        transformation
        predicates
        traversal
        ;
    };
    flattened =
      {}
      // access
      // transformation
      // predicates
      // traversal
      // {};
  };

  inherit (lib) filesystem path strings;

  access = {
    inherit (builtins) readFile;
    inherit
      (filesystem)
      baseNameOf
      dirOf
      hashFile
      pathType
      readFileType
      resolveDefaultNix
      ;
    inherit (path) splitRoot;
    inherit (strings) fileContents;
  };

  transformation = {
    inherit (builtins) path toPath;
    inherit (path) append removePrefix subpath;
  };

  predicates = {
    inherit
      (filesystem)
      isPath
      pathIsDirectory
      pathIsRegularFile
      ;

    inherit (path) isAbsolute hasPrefix hasStorePathPrefix;
    inherit (builtins) pathExists;
  };

  traversal = {
    inherit
      (filesystem)
      listFilesRecursive
      locateDominatingFile
      packagesFromDirectoryRecursive
      readDir
      ;
  };
in
  if flatten
  then __exports.namespaced // __exports.flattened
  else __exports.namespaced
