{
  lib,
  flatten ? false,
  ...
}: let
  __exports = {
    namespaced = {
      inherit
        access
        construction
        transformation
        predicates
        traversal
        ;
    };
    flattened = {} // access // construction // transformation // predicates // traversal // {};
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

  construction = {
    inherit (builtins) path toPath;
    inherit (path) subpath;
  };

  transformation = {
    inherit (path) append removePrefix;
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
