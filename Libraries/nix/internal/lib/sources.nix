{lib, ...}: let
  __exports =
    {
      inherit
        filtering
        inspection
        utils
        ;
    }
    // filtering
    // inspection
    // utils
    // {};

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
  __exports
