{
  lib,
  flatten ? false,
  ...
}: let
  __exports = {
    namespaced = {
      inherit
        access
        aggregation
        construction
        predicates
        transformation
        ;
    };
    flattened =
      access
      // aggregation
      // construction
      // predicates
      // transformation;
  };

  inherit (lib) attrsets trivial;

  access = {
    inherit
      (attrsets)
      attrNames
      attrValues
      getAttr
      attrByPath
      getAttrByPath
      collect
      foldlAttrs
      ;
  };

  construction = {
    inherit
      (attrsets)
      genAttrs
      listToAttrs
      nameValuePair
      optionalAttrs
      ;
  };

  transformation = {
    inherit
      (attrsets)
      concatMapAttrs
      filterAttrs
      filterAttrsRecursive
      mapAttrs
      mapAttrsRecursive
      mapAttrsToList
      removeAttrs
      removeAttrByPath
      setAttrByPath
      ;
    inherit (trivial) functionArgs;
  };

  aggregation = {
    inherit
      (attrsets)
      intersectAttrs
      mergeAttrsList
      recursiveUpdate
      zipAttrs
      zipAttrsWith
      ;
  };

  predicates = {
    inherit
      (attrsets)
      hasAttr
      hasAttrByPath
      isAttrs
      isDerivation
      ;
  };
in
  if flatten
  then __exports.namespaced // __exports.flattened
  else __exports.namespaced
