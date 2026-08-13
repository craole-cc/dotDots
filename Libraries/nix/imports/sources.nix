{
  lib,
  flatten ? false,
  ...
}: let
  __exports = {
    namespaced = {inherit access predicates transformation;};
    flattened = {} // access // predicates // transformation // {};
  };

  inherit (lib) attrsets meta sources strings;

  access = {
    inherit
      (sources)
      commitIdFromGitRepo
      repoRevToName
      revOrTag
      shortRev
      trace
      urlToName
      ;
    inherit (meta) getExe getExe';
    inherit (attrsets) getBin;
    inherit (builtins) getEnv;
  };

  predicates = {
    inherit (sources) canCleanSource pathHasContext pathIsGitRepo;
  };

  transformation = {
    inherit
      (sources)
      cleanSource
      cleanSourceFilter
      cleanSourceWith
      filterSource
      sourceByRegex
      sourceFilesBySuffices
      ;
    inherit (strings) makeBinPath;
  };
in
  if flatten
  then __exports.namespaced // __exports.flattened
  else __exports.namespaced
