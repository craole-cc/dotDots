{
  lib,
  flatten ? false,
  ...
}: let
  __exports = {
    namespaced = {
      inherit
        filtering
        inspection
        utils
        ;
    };
    flattened =
      {}
      // filtering
      // inspection
      // utils
      // {};
  };

  filtering = {
    inherit
      (lib.sources)
      cleanSource
      cleanSourceFilter
      cleanSourceWith
      filterSource
      sourceByRegex
      sourceFilesBySuffices
      ;
  };

  inspection = {
    inherit
      (lib.sources)
      canCleanSource
      pathHasContext
      pathIsGitRepo
      ;
  };

  utils = {
    inherit
      (lib.sources)
      commitIdFromGitRepo
      repoRevToName
      revOrTag
      shortRev
      trace
      urlToName
      ;
  };
in
  if flatten
  then __exports.namespaced // __exports.flattened
  else __exports.namespaced
