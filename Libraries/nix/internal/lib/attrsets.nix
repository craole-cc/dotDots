{
  lib,
  flatten ? false,
  ...
}: let
  __exports = {
    namespaced = {
      inherit
        construction
        folding
        merging
        predicates
        resolution
        transformation
        ;
    };
    flattened =
      {}
      // construction
      // folding
      // merging
      // predicates
      // resolution
      // transformation
      // {};
  };

  resolution = {
    inherit
      (lib.attrsets)
      attrByPath
      attrNames
      attrValues
      getAttr
      getAttrByPath
      removeAttrByPath
      setAttrByPath
      ;
  };

  construction = {
    inherit
      (lib.attrsets)
      genAttrs
      listToAttrs
      nameValuePair
      optionalAttrs
      ;
  };

  transformation = {
    inherit
      (lib.attrsets)
      concatMapAttrs
      filterAttrs
      filterAttrsRecursive
      mapAttrs
      mapAttrsRecursive
      mapAttrsToList
      removeAttrs
      ;
  };

  merging = {
    inherit
      (lib.attrsets)
      intersectAttrs
      mergeAttrsList
      recursiveUpdate
      zipAttrs
      zipAttrsWith
      ;
  };

  folding = {
    inherit
      (lib.attrsets)
      collect
      foldlAttrs
      ;
  };

  predicates = {
    inherit
      (lib.attrsets)
      hasAttr
      hasAttrByPath
      isAttrs
      ;
  };
in
  if flatten
  then __exports.namespaced // __exports.flattened
  else __exports.namespaced
