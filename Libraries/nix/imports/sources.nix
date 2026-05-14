{
  lib,
  flatten ? false,
  ...
}:
let
  __exports = {
    namespaced = { inherit access predicates transformation; };
    flattened = { } // access // predicates // transformation // { };
  };

  inherit (lib) sources;

  access = {
    inherit (sources)
      commitIdFromGitRepo
      repoRevToName
      revOrTag
      shortRev
      trace
      urlToName
      ;
  };

  predicates = { inherit (sources) canCleanSource pathHasContext pathIsGitRepo; };

  transformation = {
    inherit (sources)
      cleanSource
      cleanSourceFilter
      cleanSourceWith
      filterSource
      sourceByRegex
      sourceFilesBySuffices
      ;
  };
in
if flatten then __exports.namespaced // __exports.flattened else __exports.namespaced
